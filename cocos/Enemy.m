//
//  Enemy.m
//  Mighty Sword
//
//  Created by Alexandros Almpanis on 04/06/2013.
//  Copyright 2013 alex. All rights reserved.
//

#import "Enemy.h"
#import "Hero.h"
#import "GameLayer.h"
#import "GameOverLayer.h"
#import "Constants.h"
#import "SimpleAudioEngine.h"



@implementation Enemy

-(id) init {

    if( (self=[super init])) {
        
        [self scheduleUpdate];
                
        }
    
    self.spOpenSteps = nil;
    self.spClosedSteps = nil;
    self.shortestPath = nil;



    return self;
}

- (void)initAnimations {
    //method will be overwritten
}


-(CGRect) enemyBoundingBox {
    
    CGRect absoluteBox = CGRectMake(self.position.x, self.position.y, [self boundingBox].size.width, [self boundingBox].size.height);
        
    return absoluteBox;
}

-(CGRect)eyesightBoundingBox {

    CGRect enemySightBoundingBox;
    CGRect enemyBoundingBox = [self enemyBoundingBox];

        enemySightBoundingBox = CGRectMake(enemyBoundingBox.origin.x - 300.0f,
                                           enemyBoundingBox.origin.y - 300.0f,
                                           
                                           enemyBoundingBox.origin.x + 300.0f,
                                           enemyBoundingBox.origin.y + 300.0f);
    return enemySightBoundingBox;
    
}

- (int) getDamage {
    // method will be ovewritten for every enemy
    return 0;
}

- (void) moveTowardHero
{
    GameLayer* game = [GameLayer sharedGameLayer];

    Hero* hero = [game defaultHero];
    
    
    CGPoint fromTileCoord = [game tileCoordForPosition:self.position];
    CGPoint toTileCoord = [game tileCoordForPosition:hero.position];
    
    self.spOpenSteps = [[NSMutableArray alloc] init];
    self.spClosedSteps = [[NSMutableArray alloc] init];
    
    // Start by adding the from position to the open list
    [self insertInOpenSteps:[[ShortestPathStep alloc] initWithPosition:fromTileCoord]];
    
    do {
        // Get the lowest F cost step
        // Because the list is ordered, the first step is always the one with the lowest F cost
        ShortestPathStep *currentStep = [self.spOpenSteps objectAtIndex:0];
        
        // Add the current step to the closed set
        [self.spClosedSteps addObject:currentStep];
        
        // Remove it from the open list
        // Note that if we wanted to first removing from the open list, care should be taken to the memory
        [self.spOpenSteps removeObjectAtIndex:0];
        
        // If the currentStep is the desired tile coordinate, we are done!
        if (CGPointEqualToPoint(currentStep.position, toTileCoord)) {
            
            [self constructPathAndStartAnimationFromStep:currentStep];
            ShortestPathStep *tmpStep = currentStep;
            do {
                tmpStep = tmpStep.parent; // Go backward
            } while (tmpStep != nil); // Until there is not more parent
            
            self.spOpenSteps = nil; // Set to nil to release unused memory
            self.spClosedSteps = nil; // Set to nil to release unused memory
            break;
        }
        
        // Get the adjacent tiles coord of the current step
        NSArray *adjSteps = [game walkableAdjacentTilesCoordForTileCoord:currentStep.position];
        for (NSValue *v in adjSteps) {
            ShortestPathStep *step = [[ShortestPathStep alloc] initWithPosition:[v CGPointValue]];
            
            // Check if the step isn't already in the closed set
            if ([self.spClosedSteps containsObject:step]) {
                continue; // Ignore it
            }
            
            // Compute the cost from the current step to that step
            int moveCost = [self costToMoveFromStep:currentStep toAdjacentStep:step];
            
            // Check if the step is already in the open list
            NSUInteger index = [self.spOpenSteps indexOfObject:step];
            
            if (index == NSNotFound) { // Not on the open list, so add it
                
                // Set the current step as the parent
                step.parent = currentStep;
                
                // The G score is equal to the parent G score + the cost to move from the parent to it
                step.gScore = currentStep.gScore + moveCost;
                
                // Compute the H score which is the estimated movement cost to move from that step to the desired tile coordinate
                step.hScore = [self computeHScoreFromCoord:step.position toCoord:toTileCoord];
                
                // Adding it with the function which is preserving the list ordered by F score
                [self insertInOpenSteps:step];
                
             
            }
            else { // Already in the open list
                
                step = [self.spOpenSteps objectAtIndex:index]; // To retrieve the old one (which has its scores already computed ;-)
                
                // Check to see if the G score for that step is lower if we use the current step to get there
                if ((currentStep.gScore + moveCost) < step.gScore) {
                    
                    // The G score is equal to the parent G score + the cost to move from the parent to it
                    step.gScore = currentStep.gScore + moveCost;
                    
                    // Because the G Score has changed, the F score may have changed too
                    // So to keep the open list ordered we have to remove the step, and re-insert it with
                    // the insert function which is preserving the list ordered by F score
                    
                    // We have to retain it before removing it from the list
                    
                    // Now we can removing it from the list without be afraid that it can be released
                    [self.spOpenSteps removeObjectAtIndex:index];
                    
                    // Re-insert it with the function which is preserving the list ordered by F score
                    [self insertInOpenSteps:step];
                    
                    // Now we can release it because the oredered list retain it
                }
            }
        }
        
    } while ([self.spOpenSteps count] > 0);
    
}

// Go backward from a step (the final one) to reconstruct the shortest computed path
- (void)constructPathAndStartAnimationFromStep:(ShortestPathStep *)step
    {
        self.shortestPath = [NSMutableArray array];
        
        do {
            if (step.parent != nil) { // Don't add the last step which is the start position (remember we go backward, so the last one is the origin position ;-)
                [self.shortestPath insertObject:step atIndex:0]; // Always insert at index 0 to reverse the path
            }
            step = step.parent; // Go backward
        } while (step != nil); // Until there is no more parents
        
        for (ShortestPathStep *s in self.shortestPath) {
        }
        
        [self popStepAndAnimate];

    }

- (void)insertInOpenSteps:(ShortestPathStep *)step
{
	int stepFScore = [step fScore]; // Compute the step's F score
	int count = [self.spOpenSteps count];
	int i = 0; // This will be the index at which we will insert the step
	for (; i < count; i++) {
		if (stepFScore <= [[self.spOpenSteps objectAtIndex:i] fScore]) { // If the step's F score is lower or equals to the step at index i
			// Then we found the index at which we have to insert the new step
            // Basically we want the list sorted by F score
			break;
		}
	}
	// Insert the new step at the determined index to preserve the F score ordering
	[self.spOpenSteps insertObject:step atIndex:i];
}

// Compute the H score from a position to another (from the current position to the final desired position
- (int)computeHScoreFromCoord:(CGPoint)fromCoord toCoord:(CGPoint)toCoord
{
	// Here we use the Manhattan method, which calculates the total number of step moved horizontally and vertically to reach the
	// final desired step from the current step, ignoring any obstacles that may be in the way
	return abs(toCoord.x - fromCoord.x) + abs(toCoord.y - fromCoord.y);
}

// Compute the cost of moving from a step to an adjacent one
- (int)costToMoveFromStep:(ShortestPathStep *)fromStep toAdjacentStep:(ShortestPathStep *)toStep
{
	// Because we can't move diagonally and because terrain is just walkable or unwalkable the cost is always the same.
	// But it have to be different if we can move diagonally and/or if there is swamps, hills, etc...
	return 1;
}

- (void)popStepAndAnimate
{
    GameLayer* game = [GameLayer sharedGameLayer];
    
    
	// Check if there remains path steps to go through
	if ([self.shortestPath count] == 0) {
		self.shortestPath = nil;
		return;
	}
    
	// Get the next step to move to
	ShortestPathStep *s = [self.shortestPath objectAtIndex:0];
    
	// Prepare the action and the callback
	id moveAction = [CCMoveTo actionWithDuration:0.5 position:[game positionForTileCoord:s.position]];

    id animationAction;
    if ([game positionForTileCoord:s.position].x > self.position.x) {
        animationAction = [CCAnimate actionWithAnimation:self.walkRightAnim];
    } else if ([game positionForTileCoord:s.position].x < self.position.x) {
        animationAction = [CCAnimate actionWithAnimation:self.walkLeftAnim];
    } else if ([game positionForTileCoord:s.position].y > self.position.y) {
        animationAction = [CCAnimate actionWithAnimation:self.walkUpAnim];
    } else {
        animationAction = [CCAnimate actionWithAnimation:self.walkDownAnim];
    }
    id spawnAction =[CCSpawn actions: animationAction, moveAction, nil];

	// Remove the step
	[self.shortestPath removeObjectAtIndex:0];
    
	// Play action

    [self runAction:spawnAction];

}

-(void) update:(ccTime)delta {
    
    static int playerInvincibleCount = 15;
    static BOOL playerHit;
    
    GameLayer* game = [GameLayer sharedGameLayer];
    
    Hero* hero = [game defaultHero];
    
    // Check if hero is inside enemy's eyesight
    if (CGRectIntersectsRect(hero.heroBoundingBox, self.eyesightBoundingBox)) {

        if (self.numberOfRunningActions == 0) {

            // Chase hero
            [self moveTowardHero];
        }
            
    }
    else{
        
        [self stopAllActions];
    }
    
    // Check for collision between arrow and enemy
    if (CGRectIntersectsRect(hero.arrowBoundingBox, self.enemyBoundingBox)) {
        
        [hero.arrow removeFromParentAndCleanup:YES];
        hero.arrow = nil;
        
        self.health -= hero.getDamage;
        
        if (self.health <= 0) {
            [game removeChild:self cleanup:YES];
            [hero recieveXP:kReceiveXP];
            
            
        }
    }
    // Check for collision between hero and enemy
    if (CGRectIntersectsRect(hero.heroBoundingBox, self.enemyBoundingBox)) {
        
        // Hero can't shoot while taking damage
        hero.canShoot = NO;
        
        if (playerInvincibleCount == 15) {
            
        playerHit = YES;
            
        hero.heroHealth = hero.heroHealth - self.getDamage;
        NSLog(@"health%i",hero.heroHealth);
        }
    }
    else {
        hero.canShoot = YES;
    }
    
    // Hero is invincible for 15 frames
    if(playerHit) {
        if(playerInvincibleCount > 0) {
            playerInvincibleCount--;
        } else {
            playerHit = NO;
            playerInvincibleCount = 15;
        }
    }
    
    if (hero.heroHealth <= 0) {
        
        [[SimpleAudioEngine sharedEngine] stopEffect:hero.soundEffectID];

    
        CCScene *gameOverScene = [GameOverLayer scene];
        [[CCDirector sharedDirector] replaceScene:gameOverScene];
    }
}

@end