#import <ParseKit/PKSParser.h>

enum {
    METHODSFACTORED_TOKEN_KIND_INT = 14,
    METHODSFACTORED_TOKEN_KIND_CLOSE_CURLY,
    METHODSFACTORED_TOKEN_KIND_COMMA,
    METHODSFACTORED_TOKEN_KIND_VOID,
    METHODSFACTORED_TOKEN_KIND_OPEN_PAREN,
    METHODSFACTORED_TOKEN_KIND_OPEN_CURLY,
    METHODSFACTORED_TOKEN_KIND_CLOSE_PAREN,
    METHODSFACTORED_TOKEN_KIND_SEMI_COLON,
};

@interface MethodsFactoredParser : PKSParser

@end

