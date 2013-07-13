//
//  GameLayer.m
//  cocos
//
//  Created by alex on 06/03/2013.
//  Copyright alex 2013. All rights reserved.
//


// Import the interfaces
#import "GameLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"
#import "InputLayer.h"
#import "Enemy.h"


#pragma mark - GameLayer

// GameLayer implementation

@implementation GameLayer

@synthesize bgLayer = _bgLayer,themap =_themap;

static GameLayer* sharedGameLayer;
+(GameLayer*) sharedGameLayer
{
	NSAssert(sharedGameLayer != nil, @"GameScene instance not yet initialized!");
	return sharedGameLayer;
}

// Helper class method that creates a Scene with the GameLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
    
    // 'layer' is an autorelease object.
	GameLayer *layer = [GameLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
    
    InputLayer* inputLayer=[InputLayer node];
    [scene addChild:inputLayer z:1];
    


	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init]) ) {
        
        sharedGameLayer = self;

        
        CCSpriteFrameCache* frameCache = [CCSpriteFrameCache sharedSpriteFrameCache];
        [frameCache addSpriteFramesWithFile:@"heroenemy.plist"];
		
        self.themap = [CCTMXTiledMap tiledMapWithTMXFile:@"map1.tmx"];
        self.bgLayer = [_themap layerNamed:@"bg"];
        [self addChild:_themap z:-1];
        
    }
    
    Hero* hero = [Hero hero];
    hero.tag = 1;

    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;

    [hero setPosition:ccp(screenHeight/2 , screenWidth/2)];
    [self addChild:hero];
    
    Enemy* enemy = [Enemy enemyWithType:EnemyType1];
    [enemy setPosition:ccp(100,100)];
    [self addChild:enemy];

    [self scheduleUpdate];                                   

    
    return self;

}

-(void) update:(ccTime)deltaTime {

    [self.delegate setJoystickToHero];
    
}

-(Hero*) defaultHero
{
	CCNode* node = [self getChildByTag:1];
	NSAssert([node isKindOfClass:[Hero class]], @"node is not a Hero!");
	return (Hero*)node;
}

- (CGPoint)tileCoordForPosition:(CGPoint)position {
    int x = position.x / _themap.tileSize.width;
    int y = ((_themap.mapSize.height * _themap.tileSize.height) - position.y) / _themap.tileSize.height;
    return ccp(x, y);
}

- (CGPoint)positionForTileCoord:(CGPoint)tileCoord {
    int x = (tileCoord.x * _themap.tileSize.width) + _themap.tileSize.width/2;
    int y = (_themap.mapSize.height * _themap.tileSize.height) - (tileCoord.y * _themap.tileSize.height) - _themap.tileSize.height/2;
    return ccp(x, y);
}

- (BOOL)isValidTileCoord:(CGPoint)tileCoord {
    if (tileCoord.x < 0 || tileCoord.y < 0 ||
        tileCoord.x >= _themap.mapSize.width ||
        tileCoord.y >= _themap.mapSize.height) {
        return FALSE;
    } else {
        return TRUE;
    }
}

-(BOOL)isProp:(NSString*)prop atTileCoord:(CGPoint)tileCoord forLayer:(CCTMXLayer *)layer {
    if (![self isValidTileCoord:tileCoord]) return NO;
    int gid = [layer tileGIDAt:tileCoord];
    NSDictionary * properties = [_themap propertiesForGID:gid];
    if (properties == nil) return NO;
    return [properties objectForKey:prop] != nil;
}

-(BOOL)isWallAtTileCoord:(CGPoint)tileCoord {
    return [self isProp:@"Wall" atTileCoord:tileCoord forLayer:_bgLayer];
}

- (NSArray *)walkableAdjacentTilesCoordForTileCoord:(CGPoint)tileCoord
{
	NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:4];
    
	// Top
	CGPoint p = CGPointMake(tileCoord.x, tileCoord.y - 1);
	if ([self isValidTileCoord:p] && ![self isWallAtTileCoord:p]) {
		[tmp addObject:[NSValue valueWithCGPoint:p]];
	}
    
	// Left
	p = CGPointMake(tileCoord.x - 1, tileCoord.y);
	if ([self isValidTileCoord:p] && ![self isWallAtTileCoord:p]) {
		[tmp addObject:[NSValue valueWithCGPoint:p]];
	}
    
	// Bottom
	p = CGPointMake(tileCoord.x, tileCoord.y + 1);
	if ([self isValidTileCoord:p] && ![self isWallAtTileCoord:p]) {
		[tmp addObject:[NSValue valueWithCGPoint:p]];
	}
    
	// Right
	p = CGPointMake(tileCoord.x + 1, tileCoord.y);
	if ([self isValidTileCoord:p] && ![self isWallAtTileCoord:p]) {
		[tmp addObject:[NSValue valueWithCGPoint:p]];
	}
    
	return [NSArray arrayWithArray:tmp];
}

// on "dealloc" you need to release all your retained objects

#pragma mark GameKit delegate

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissViewControllerAnimated:YES completion:nil];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissViewControllerAnimated:YES completion:nil];
}
@end