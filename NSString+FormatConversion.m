//
//  NSString+DateConversion.m
//  Mib.io
//
//  Created by Ben Gotow on 6/7/12.
//  Copyright (c) 2012 Foundry376. All rights reserved.
//

#import "NSString+FormatConversion.h"
#import <CommonCrypto/CommonDigest.h>
#import <CoreText/CoreText.h>

static NSMutableDictionary * formatters;


@implementation NSString (FormatConversion)

+ (NSDateFormatter*)formatterForFormat:(NSString*) f
{
    if (formatters == nil)
        formatters = [[NSMutableDictionary alloc] init];
    
    NSDateFormatter * formatter = [formatters objectForKey: f];
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat: f];
        [formatter setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT:0]];
        [formatters setObject: formatter forKey: f];
    }
    return formatter;
}

+ (NSString*)stringWithDate:(NSDate*)date format:(NSString*)f
{
    return [[NSString formatterForFormat: f] stringFromDate: date];
}

- (NSDate*)dateValueWithFormat:(NSString*)f
{
    return [[NSString formatterForFormat: f] dateFromString: self];
}

- (NSString*)md5Value
{
    const char *cStr = [self UTF8String];
    unsigned char digest[16];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    return  output;
}

+ (NSString *)generateUUIDWithExtension:(NSString*)ext
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    NSString * s = (NSString *)CFBridgingRelease(string);
    if (ext)
        s = [s stringByAppendingFormat:@".%@", ext];
    return s;
}

- (NSString *)urlencode
{
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[self UTF8String];
    unsigned long sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

+ (NSString*)stringWithCGSize:(CGSize)size
{
    return [NSString stringWithFormat:@"%f,%f", size.width, size.height];
}

- (CGSize)CGSizeValue
{
    NSArray * components = [self componentsSeparatedByString: @","];
    return CGSizeMake([[components objectAtIndex: 0] doubleValue], [[components objectAtIndex: 1] doubleValue]);
}

- (id)asJSONObjectOfClass:(Class)klass
{
    if ([self length] == 0)
        return nil;
    
    NSData * data = [self dataUsingEncoding: NSUTF8StringEncoding];
    id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:NULL];
    if ([obj isKindOfClass: klass])
        return obj;
    else
        return nil;
}

- (NSAttributedString*)attributedTextWithFont:(UIFont*)font andColor:(UIColor*)color andLineSpacing:(int)lineSpacing
{
    NSMutableAttributedString * attributed = [[NSMutableAttributedString alloc] initWithString: self];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    NSRange all = NSMakeRange(0, [attributed length]);
    [style setLineBreakMode: NSLineBreakByWordWrapping];
    [style setLineSpacing: lineSpacing];
    [attributed addAttribute:NSFontAttributeName value:font range:all];
    [attributed addAttribute:NSForegroundColorAttributeName value:color range:all];
    [attributed addAttribute:NSParagraphStyleAttributeName value:style range: all];
    
    return attributed;
}

@end

@implementation NSAttributedString (FormatConversion)

- (float)heightConstrainedToWidth:(float)width
{
    if ([self length] == 0)
        return 0;
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self);
    CGSize targetSize = CGSizeMake(width, CGFLOAT_MAX);
    CGSize size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [self length]), NULL, targetSize, NULL);
    CFRelease(framesetter);
    return size.height+5;
}

@end
