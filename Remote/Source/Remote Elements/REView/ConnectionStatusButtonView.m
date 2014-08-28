//
// ConnectionStatusButtonView.m
// Remote
//
// Created by Jason Cardwell on 5/24/11.
// Copyright 2011 Moondeer Studios. All rights reserved.
//
#import "RemoteElementView_Private.h"
#import "Button.h"
#import "ConnectionManager.h"

@implementation ConnectionStatusButtonView {}

- (void)initializeIVARs {
  [super initializeIVARs];

  self.selected = [ConnectionManager isWifiAvailable];

  [NotificationCenter
     addObserverForName:CMConnectionStatusNotification
                 object:[ConnectionManager class]
                  queue:MainQueue
             usingBlock:^(NSNotification * note) {
               if (self.model.selected != BOOLValue([note.userInfo
                                             valueForKey:CMConnectionStatusWifiAvailable]))
                 self.model.selected = !self.model.selected;
             }];
}

- (void)dealloc { [NotificationCenter removeObserver:self]; }

@end
