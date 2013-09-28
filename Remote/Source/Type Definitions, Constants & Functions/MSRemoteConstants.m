//
// Constants.m
// Remote
//
// Created by Jason Cardwell on 6/19/11.
// Copyright 2011 Moondeer Studios. All rights reserved.
//

#import "MSRemoteConstants.h"

MSSTRING_CONST MSDefaultFontName     = @"Optima-Bold";
MSSTRING_CONST MSArrowFontName       = @"HiraMinProN-W6";
MSSTRING_CONST MSUpArrow             = @"\u25B2";
MSSTRING_CONST MSDownArrow           = @"\u25BC";
MSSTRING_CONST MSLeftArrow           = @"\u25C0";
MSSTRING_CONST MSRightArrow          = @"\u25B6";

const int   kQueueKey = 121;

UIColor * defaultTitleHighlightColor(void) {
    static UIColor * color;

    if (ValueIsNil(color)) color = [UIColor colorWithRed:0 green:175.0 / 255.0 blue:1.0 alpha:1.0];

    return color;
}

UIColor * defaultTitleColor(void) {
    static UIColor * color;

    if (ValueIsNil(color)) color = [UIColor whiteColor];

    return color;
}

UIColor * defaultBGColor(void) {
    static UIColor * color;

    if (ValueIsNil(color)) color = [[UIColor darkTextColor] colorWithAlphaComponent:1.0];

    return color;
}

UIColor * defaultGlossColor(void) {
    static UIColor * color;

    if (ValueIsNil(color)) color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.02];

    return color;
}

UIFont * defaultFont(void) {
    static UIFont * font;

    if (ValueIsNil(font)) font = [UIFont systemFontOfSize:[UIFont systemFontSize]];

    return font;
}

