//
//  ANSNSAttributedStringToNSDictionaryValueTransformer.m
//  AnalysysAgent
//
//  Created by analysys on 2018/4/9.
//  Copyright © 2018年 analysys. All rights reserved.
//
//  Copyright (c) 2014 Mixpanel. All rights reserved.


#import "ANSValueTransformers.h"
#import "AnalysysLogger.h"

@implementation ANSNSAttributedStringToNSDictionaryValueTransformer

+ (Class)transformedValueClass {
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if ([value isKindOfClass:[NSAttributedString class]]) {
        NSMutableAttributedString *attributedString = [value mutableCopy];
        [attributedString beginEditing];
        __block BOOL safe = NO;
        [attributedString enumerateAttribute:NSParagraphStyleAttributeName inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
            if (value) {
                NSParagraphStyle *paragraphStyle = value;
                if([paragraphStyle respondsToSelector:@selector(headIndent)]) {
                    safe = YES;
                }
            }
        }];
        if (!safe) {
            [attributedString removeAttribute:NSParagraphStyleAttributeName range:NSMakeRange(0, attributedString.length)];
        }
        [attributedString endEditing];
        
        NSError *error = nil;
        NSData *data = [attributedString dataFromRange:NSMakeRange(0, attributedString.length)
                                    documentAttributes:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType}
                                                 error:&error];
        if (data) {
            return @{
                     @"mime_type": @"text/html",
                     @"data": [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
                     };
        } else {
            ANSDebug(@"Failed to convert NSAttributedString to HTML: %@", error);
        }
    }
    
    return nil;
}

- (id)reverseTransformedValue:(id)value {
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionaryValue = value;
        NSString *mimeType = dictionaryValue[@"mime_type"];
        NSString *dataString = dictionaryValue[@"data"];
        
        if ([mimeType isEqualToString:@"text/html"] && dataString) {
            NSError *error = nil;
            NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
            NSAttributedString *attributedString = [[NSAttributedString alloc] initWithData:data
                                                                                    options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType}
                                                                         documentAttributes:NULL
                                                                                      error:&error];
            if (attributedString == nil) {
                ANSDebug(@"Failed to convert HTML to NSAttributed string: %@", error);
            }
            
            return attributedString;
        }
    }
    
    return nil;
}

@end
