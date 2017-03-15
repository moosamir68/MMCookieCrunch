//
//  GameViewController.m
//  CookieCrunch
//
//  Created by Moosa Mir on 3/8/17.
//  Copyright © 2017 Moosa Mir. All rights reserved.
//
@import AVFoundation;

#import "MMGameViewController.h"
#import "MMGameScene.h"
#import "MMLevel.h"

@interface MMGameViewController(){
    NSUInteger _numberOflevel;
}
@property (nonatomic, strong) MMGameScene *scene;
@property (nonatomic, strong) MMLevel *level;

@property (nonatomic, assign) NSUInteger moveLeft;
@property (nonatomic, assign) NSUInteger score;

@property (weak, nonatomic) IBOutlet UILabel *targetValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *movesValueLabels;
@property (weak, nonatomic) IBOutlet UILabel *scoreValueLabels;

@property (weak, nonatomic) IBOutlet UIImageView *gameoverPanel;
@property (weak, nonatomic) IBOutlet UIButton *shuffleButton;

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic, strong) AVAudioPlayer *backgroundMusic;
@property (weak, nonatomic) IBOutlet UILabel *levellabel;
@end

@implementation MMGameViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    _numberOflevel = 1;
    [self.gameoverPanel setHidden:YES];
    //configutr view
    SKView *skView = (SKView*)self.view;
    [skView setMultipleTouchEnabled:NO];
    
    //create and configure game scnce
    [self setScene:[MMGameScene sceneWithSize:skView.bounds.size]];
    [self.scene setScaleMode:SKSceneScaleModeAspectFill];
    
    //load the level
    [self setLevel:[[MMLevel alloc] initWithFile:@"Level_1"]];
    [self.scene setLevel:self.level];
    [self.scene addTiles];
    
    id block = ^(MMSwap *swap){
        self.view.userInteractionEnabled = NO;
        
        if([self.level isPossibleSape:swap]){
            [self.level performSwap:swap];
            [self.scene animateSwipe:swap completion:^{
                [self handleMatches];
                self.view.userInteractionEnabled = YES;
            }];
        }else{
            [self.scene animateInvalidSwipe:swap completion:^{
                self.view.userInteractionEnabled = YES;
            }];
        }
    };
    self.scene.swipeHandler = block;
    
    //present the scene
    [skView presentScene:self.scene];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"Mining by Moonlight" withExtension:@"mp3"];
    self.backgroundMusic = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.backgroundMusic.numberOfLoops = -1;
    [self.backgroundMusic play];
    
    //lets start game
    [self beginGame];
}

#pragma mark - shuffle and begin game
- (void)beginGame{
    self.score = 0;
    self.moveLeft = self.level.maximumMoves;
    [self updateLabels];
    [self.level resetComboMultiPlier];
    [self.scene animateBegianGame];
    [self shuffle];
}

- (void)shuffle{
    [self.scene removeAllCookieSprit];
    [self.scene removeTiles];
    [self loadNextLevel];
    [self.scene addTiles];
    NSSet *newCookies = [self.level shuffle];
    [self.scene addSpritesForCookies:newCookies];
    [self setTitleLevel];
}

- (void)loadNextLevel{
    NSString *fileName;
    switch (_numberOflevel) {
        case 1:
            fileName = @"Level_1";
            break;
        case 2:
            fileName = @"Level_2";
            break;
        case 3:
            fileName = @"Level_3";
            break;
        case 4:
            fileName = @"Level_4";
            break;
        default:
            fileName = @"Level_4";
            break;
    }
    
    [self.level resetTils:fileName];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - handle matches
- (void)handleMatches{
    NSSet *chains = [self.level removeMatches];
    if([chains count] == 0){
        [self beginNextTurn];
        return;
    }
    [self.scene animateMatchedCookies:chains completion:^{
        for(MMChain *chain in chains){
            self.score +=chain.score;
        }
        [self updateLabels];
        NSArray *columns = [self.level fillHoles];
        [self.scene animateFallingCookies:columns completion:^{
            NSArray *columns = [self.level topUpCookies];
            [self.scene animateNewCookies:columns completion:^{
                [self handleMatches];
            }];
        }];
    }];
}

#pragma mark - begin next turn
- (void)beginNextTurn{
    [self.level resetComboMultiPlier];
    [self.level detectPossibleSwape];
    self.view.userInteractionEnabled = YES;
    [self decrimentMoves];
}

#pragma mark -update labels
- (void)updateLabels{
    [self.targetValueLabel setText:[NSString stringWithFormat:@"%lu",(long)self.level.targetScore]];
    [self.movesValueLabels setText:[NSString stringWithFormat:@"%lu",(long)self.moveLeft]];
    [self.scoreValueLabels setText:[NSString stringWithFormat:@"%lu",(long)self.score]];
}

#pragma mark -  decriment moves
- (void)decrimentMoves{
    self.moveLeft--;
    [self updateLabels];
    if(self.score >= self.level.targetScore){
        [self.gameoverPanel setImage:[UIImage imageNamed:@"LevelComplete"]];
        [self showGameover];
        _numberOflevel++;
    }else if(self.moveLeft == 0){
        [self.gameoverPanel setImage:[UIImage imageNamed:@"GameOver"]];
        [self showGameover];
    }
}

#pragma mark - show gameover panel
- (void)showGameover{
    [self.scene animateGameover];
    self.shuffleButton.hidden = YES;
    self.levellabel.hidden = YES;
    [self.gameoverPanel setHidden:NO];
    self.scene.userInteractionEnabled = NO;
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideGameoverPanel)];
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
}

#pragma mark - hide gameover panel
- (void)hideGameoverPanel{
    self.shuffleButton.hidden = NO;
    self.levellabel.hidden = NO;
    [self.view removeGestureRecognizer:self.tapGestureRecognizer];
    self.tapGestureRecognizer = nil;
    
    [self.gameoverPanel setHidden:YES];
    self.scene.userInteractionEnabled = YES;
    
    [self beginGame];
}
#pragma mark - user did tap on shufle
- (IBAction)userDidTapOnShufle:(id)sender {
    [self shuffle];
    [self decrimentMoves];
}

- (void)setTitleLevel{
    NSString *titleString;
    switch (_numberOflevel) {
        case 1:
            titleString = @"Level 1";
            break;
        case 2:
            titleString = @"Level 2";
            break;
        case 3:
            titleString = @"Level 3";
            break;
        case 4:
            titleString = @"Level 4";
            break;
        default:
            titleString = @"Level 4";
            break;
    }
    
    [self.levellabel setText:titleString];
}
@end
