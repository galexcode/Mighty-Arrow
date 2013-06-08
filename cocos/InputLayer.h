//
//  InputLayer.h
//  cocos
//
//  Created by alex on 23/05/2013.
//  Copyright (c) 2013 alex. All rights reserved.
//

#import "CCLayer.h"
#import "GameLayer.h"
#import "SneakyButton.h"
#import "SneakyButtonSkinnedBase.h"
#import "SneakyJoystick.h"
#import "SneakyJoystickSkinnedBase.h"



@interface InputLayer : CCLayer <GameLayerProtocol> {

SneakyJoystick* sJoystick;
SneakyButton* attackButton;
}

@property(nonatomic, strong) SneakyJoystick* sJoystick;


@end
