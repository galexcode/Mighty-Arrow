//
//  Enemy.h
//  cocos
//
//  Created by alex on 04/06/2013.
//  Copyright 2013 alex. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef enum
{
    EnemyType1 = 0,
    EnemyType2,
    EnemyType3,
    
    EnemyType_MAX,
} EnemyTypes;

@interface Enemy : CCSprite {
  
    EnemyTypes type;
    int initialHitPoints;
    int hitPoints;
}

@property (readonly, nonatomic) int initialHitPoints;
@property (readonly, nonatomic) int hitPoints;

+(id) enemyWithType:(EnemyTypes)enemyType;

@end