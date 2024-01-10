//
//  VAValidation.m
//  LaunchBoard
//
//  Created by Vlad Alexa on 1/11/11.
//  Copyright 2011 NextDesign. All rights reserved.
//

#import "VAValidation.h"

#import <sys/stat.h>
#import <openssl/bio.h>
#import <openssl/pkcs7.h>
#import <openssl/x509.h>
#import <Security/SecKeychainItem.h>
#import <Security/CodeSigning.h>
#import <objc/runtime.h>
#import "Payload.h"
#import "ethernet.h"

typedef int (*startup_call_t)(int, const char **);

static inline SecCertificateRef AppleRootCA( void )
{
    SecKeychainRef roots = NULL;
    SecKeychainSearchRef search = NULL;
    SecCertificateRef cert = NULL;
    
    OSStatus err = SecKeychainOpen( "/System/Library/Keychains/SystemRootCertificates.keychain", &roots );
	
    if ( err != noErr )
    {
        CFStringRef errStr = SecCopyErrorMessageString( err, NULL );
        NSLog( @"Error: %d (%@)", err, errStr );
        CFRelease( errStr );
        return NULL;
    }
    
    SecKeychainAttribute labelAttr = { .tag = kSecLabelItemAttr, .length = 13, .data = (void *)"Apple Root CA" };
    SecKeychainAttributeList attrs = { .count = 1, .attr = &labelAttr };
    
    err = SecKeychainSearchCreateFromAttributes( roots, kSecCertificateItemClass, &attrs, &search ); 
    if ( err != noErr )
    {
        CFStringRef errStr = SecCopyErrorMessageString( err, NULL );
        NSLog( @"Error: %d (%@)", err, errStr );
        CFRelease( errStr );
        CFRelease( roots );		
        return NULL;
    }
    
    SecKeychainItemRef item = NULL;
    err = SecKeychainSearchCopyNext( search, &item );   
    if ( err != noErr )
    {
        CFStringRef errStr = SecCopyErrorMessageString( err, NULL );
        NSLog( @"Error: %d (%@)", err, errStr );
        CFRelease( errStr );
        CFRelease( roots );		
        return NULL;
    }
    
    cert = (SecCertificateRef)item;
    CFRelease( search );
	CFRelease( roots );
    
    return ( cert );
}

static inline int aCheck( int argc, startup_call_t *theCall, id * receiptPath )
{
	BOOL GCenabled = NO;	
    
    if ([NSGarbageCollector defaultCollector] != nil ) GCenabled = YES;
    
    // the pkcs7 container (the receipt) and the output of the verification
    PKCS7 *p7 = NULL;
    
    // The Apple Root CA in its OpenSSL representation.
    X509 *Apple = NULL;
    
    // The root certificate for chain-of-trust verification
    X509_STORE *store = X509_STORE_new();
    
    // initialize both BIO variables using BIO_new_mem_buf() with a buffer and its size...
    //b_p7 = BIO_new_mem_buf((void *)[receiptData bytes], [receiptData length]);
    FILE *fp = fopen( [*receiptPath fileSystemRepresentation], "rb" );
    
    // initialize b_out as an out
    BIO *b_out = BIO_new(BIO_s_mem());
    
    // capture the content of the receipt file and populate the p7 variable with the PKCS #7 container
    if (fp != NULL) {
        p7 = d2i_PKCS7_fp( fp, NULL );
        fclose( fp );        
    }
    
    // get the Apple root CA from http://www.apple.com/certificateauthority and load it into b_X509
    //NSData * root = [NSData dataWithContentsOfURL: [NSURL URLWithString: @"http://www.apple.com/certificateauthority/AppleComputerRootCertificate.cer"]];
    SecCertificateRef cert = AppleRootCA();
    if (GCenabled == YES) CFMakeCollectable(cert);    
    if ( cert == NULL )
    {
        NSLog( @"Failed to load Apple Root CA" );
        *theCall = (startup_call_t)&exit;
        return ( 173 );
    }
    
    CFDataRef data = SecCertificateCopyData( cert );
    if (GCenabled == YES) CFMakeCollectable(data);    
    if (GCenabled == NO) CFRelease( cert );
    
    //b_x509 = BIO_new_mem_buf( (void *)CFDataGetBytePtr(data), (int)CFDataGetLength(data) );
    const unsigned char * pData = CFDataGetBytePtr(data);
    Apple = d2i_X509( NULL, &pData, (long)CFDataGetLength(data) );
    X509_STORE_add_cert( store, Apple );
    
    // verify the signature. If the verification is correct, b_out will contain the PKCS #7 payload and rc will be 1.
    int rc = PKCS7_verify( p7, NULL, store, NULL, b_out, 0 );
    
    // could also verify the fingerprints of the issue certificates in the receipt
    
    unsigned char *pPayload = NULL;
    size_t len = BIO_get_mem_data(b_out, &pPayload);
    *receiptPath = [NSData dataWithBytes: pPayload length: len];
    
    // clean up
    //BIO_free(b_p7);
    //BIO_free(b_x509);
    BIO_free(b_out);
    PKCS7_free(p7);
    X509_free(Apple);
    X509_STORE_free(store);
    if (GCenabled == NO) CFRelease(data);
    
    if ( rc != 1 )
    {
        *theCall = (startup_call_t)&exit;
        return ( 173 );
    }
    
    return ( argc );
}

static inline int hCheck( int argc, startup_call_t *theCall, id * dataPtr, id b)
{
    NSData * payloadData = (NSData *)(*dataPtr);
    void * data = (void *)[payloadData bytes];
    size_t len = (size_t)[payloadData length];
    
    Payload_t * payload = NULL;
    asn_dec_rval_t rval;
    
    // parse the buffer using the asn1c-generated decoder.
    do
    {
        rval = asn_DEF_Payload.ber_decoder( NULL, &asn_DEF_Payload, (void **)&payload, data, len, 0 );
        
    } while ( rval.code == RC_WMORE );
    
    if ( rval.code == RC_FAIL )
    {
        *theCall = (startup_call_t)&exit;
        return ( 173 );
    }
    
    OCTET_STRING_t *bundle_id = NULL;
    OCTET_STRING_t *bundle_version = NULL;
    OCTET_STRING_t *opaque = NULL;
    OCTET_STRING_t *hash = NULL;
    
    // iterate over the attributes, saving the values required for the hash
    size_t i;
    for ( i = 0; i < payload->list.count; i++ )
    {
        ReceiptAttribute_t *entry = payload->list.array[i];
        switch ( entry->type )
        {
            case 2:
                bundle_id = &entry->value;
                break;
            case 3:
                bundle_version = &entry->value;
                break;
            case 4:
                opaque = &entry->value;
                break;
            case 5:
                hash = &entry->value;
                break;
            default:
                break;
        }
    }
    
    if ( bundle_id == NULL || bundle_version == NULL || opaque == NULL || hash == NULL )
    {        
        free( payload );
        *theCall = (startup_call_t)&exit;
        return ( 173 );
    }
    
    NSString * bidStr = [[[NSString alloc] initWithBytes: (bundle_id->buf + 2) length: (bundle_id->size - 2) encoding: NSUTF8StringEncoding] autorelease];
    if ( [bidStr isEqualToString: [b bundleIdentifier]] == NO )
    {
        //bundle id of receipt is not the same as our own   
        free( payload );
        *theCall = (startup_call_t)&exit;
        return ( 173 );
    }
    
    NSString * dvStr = [[[NSString alloc] initWithBytes: (bundle_version->buf + 2) length: (bundle_version->size - 2) encoding: NSUTF8StringEncoding] autorelease];
    if ( [dvStr isEqualToString: [[b infoDictionary] objectForKey: @"CFBundleShortVersionString"]] == NO )
    {
        //version of receipt is not the same as our own
        free( payload );
        *theCall = (startup_call_t)&exit;
        return ( 173 );
    }
    
    CFDataRef macAddress = CopyMACAddressData();
    if ( macAddress == NULL )
    {
        free( payload );
        *theCall = (startup_call_t)&exit;
        return ( 173 );
    }
    
    UInt8 *guid = (UInt8 *)CFDataGetBytePtr( macAddress );
    size_t guid_sz = CFDataGetLength( macAddress );
    
    // initialize an EVP context for OpenSSL
    EVP_MD_CTX evp_ctx;
    EVP_MD_CTX_init( &evp_ctx );
    
    UInt8 digest[20];
    
    // set up EVP context to compute an SHA-1 digest
    EVP_DigestInit_ex( &evp_ctx, EVP_sha1(), NULL );
    
    // concatenate the pieces to be hashed. They must be concatenated in this order.
    EVP_DigestUpdate( &evp_ctx, guid, guid_sz );
    EVP_DigestUpdate( &evp_ctx, opaque->buf, opaque->size );
    EVP_DigestUpdate( &evp_ctx, bundle_id->buf, bundle_id->size );
    
    // compute the hash, saving the result into the digest variable
    EVP_DigestFinal_ex( &evp_ctx, digest, NULL );
    
    // clean up memory
    EVP_MD_CTX_cleanup( &evp_ctx );
    
    // compare the hash
    int match = sizeof(digest) - hash->size;
    match |= memcmp( digest, hash->buf, MIN(sizeof(digest), hash->size) );
    
    free( payload );
    if ( match != 0 )
    {        
        *theCall = (startup_call_t)&exit;
        return ( 173 );
    }
    
    return ( argc );
}


@implementation VAValidation

+(int)v{	
	return [VAValidation v:[NSBundle mainBundle]];	
}

+(int)a{
    //check if the app is signed for the store as to work in xcode with development signature
    NSArray *certs = [VAValidation certificatesFor:[[NSBundle mainBundle] bundlePath]];
    if (![certs containsObject:@"Apple Mac OS Application Signing"]) {
        NSLog(@"Not a MAS app");
        return 0;
    }    
	return [VAValidation a:[NSBundle mainBundle]];			
}

+(int)v:(NSBundle*)b{
    if ([NSGarbageCollector defaultCollector] != nil ) NSLog(@"This is running under GC, might hit apple bug rdar:9126150, SecStaticCodeCheckValidity retains staticCode under GC and 5%% of the times this will crash");    
	//check the app signature
	int ret = -1;
    SecStaticCodeRef staticCode = NULL;
	OSStatus existence = SecStaticCodeCreateWithPath((CFURLRef)[b bundleURL], kSecCSDefaultFlags, &staticCode);
    OSStatus validity = -1;    
    if (existence == noErr){
        validity = SecStaticCodeCheckValidity(staticCode, kSecCSCheckAllArchitectures, NULL); //if invalid crashes with: The code signature is not valid: The operation couldn’t be completed. (OSStatus error -67061.)        
        CFRelease(staticCode); //apple bug rdar:9126150, SecStaticCodeCheckValidity retains staticCode under GC and 5% of the times this will crash with (SecKeychain[512]): over-retained during finalization, refcount = 1
    }else{
        if (b == [NSBundle mainBundle]) [NSApp terminate:self];        
        NSLog(@"SecStaticCodeCreateWithPath failed for %@",[b bundlePath]);
    }	
    if (validity == errSecSuccess){
        //NSLog(@"Validated %@",[b bundlePath]);
    }else{
        if (b == [NSBundle mainBundle]) [NSApp terminate:self];        
        NSLog(@"SecStaticCodeCheckValidity failed for %@",[b bundlePath]);        
    }	
    if ( existence == noErr && validity == noErr ) {
        //ok
        ret = 0;
    }else {
        if (b == [NSBundle mainBundle]) {
            //was hacked, should have exited by now
            ret = 1;					
        }
    }      
	return ret;
}


+(int)a:(NSBundle*)b
{   
	//check if the app has a receipt, exit 173 otherwise
	id obj_arg = [[[b bundlePath] stringByAppendingPathComponent:@"Contents/_MASReceipt/receipt"] stringByStandardizingPath];
    struct stat statBuf;	
    if ( stat([obj_arg fileSystemRepresentation], &statBuf) != 0){
		if (b == [NSBundle mainBundle]) {
			exit(173);			
		}else {
			return -1;
		}
	}	
	
	//check the receipt and signature, return exit code
    ERR_load_PKCS7_strings();
    ERR_load_X509_strings();
    OpenSSL_add_all_digests();	
	startup_call_t theCall = &NSApplicationMain;;
	int ret = 0;	    
	ret += aCheck(ret, &theCall, &obj_arg); //check that receipt is signed by apple 
	ret += hCheck(ret, &theCall, &obj_arg, b); //check the receipt hash    
	return ret;	
}

+ (NSArray*)certificatesFor:(NSString*)path
{
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:1];
    
    CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:path];
    if (url) {        
        SecStaticCodeRef codeRef;
        if (SecStaticCodeCreateWithPath(url, kSecCSDefaultFlags, &codeRef) == noErr) {
            if (SecStaticCodeCheckValidity(codeRef, kSecCSBasicValidateOnly, NULL) == errSecSuccess) {
                CFDictionaryRef api;
                if (SecCodeCopySigningInformation(codeRef, kSecCSSigningInformation, &api) == noErr) {  
                    NSArray *certs = [(NSDictionary*)api objectForKey:(NSString*)kSecCodeInfoCertificates];
                    for (id cert in certs) {
                        CFStringRef commonName;
                        SecCertificateCopyCommonName((SecCertificateRef)cert, &commonName);
                        if (commonName) {
                            [ret addObject:[NSString stringWithString:(NSString*)commonName]];
                            CFRelease(commonName);                            
                        }
                    }                     
                }
                CFRelease(api);
            }
            CFRelease(codeRef);
        }else {
            NSLog(@"SecStaticCodeCreateWithPat failed for %@",url);
        }
    }
    return ret;    
}

@end
