//
//  BarGraph.m
//  GraphKit
//
//  Created by Sunil Rao on 02/05/16.
//  Copyright © 2016 Sunil Rao. All rights reserved.
//

#import "BarGraph.h"

@interface BarGraph()

@property (nonatomic,strong) NSArray *dataArray;
@property (nonatomic,strong) GraphScale *scale;
@property (nonatomic,strong) NSMutableArray *coordinatePointsArray;
@property (nonatomic) BOOL isLayoutNeeded;
@property (nonatomic,assign) float spacingX;
@property (nonatomic,assign) float spacingY;
@property (nonatomic,strong)NSMutableArray *xDataLable;
@property (nonatomic,strong)NSMutableArray *yDataLable;
@property (nonatomic,strong) CAShapeLayer *graphLayout;

@end

@implementation BarGraph
{
    NSMutableArray *gradientMaskArray;
}

//Initializing data
- (instancetype)initWithDataSource:(NSArray *)dataArray graphScale:(GraphScale *)scale andGraphLayoutNeeded:(BOOL)layoutNeeded;
{
    self =[super init];
    
    if (self)
    {
        self.backgroundColor = [UIColor whiteColor];
        self.dataArray = dataArray;
        self.scale = scale;
        self.isLayoutNeeded = layoutNeeded;
        //To redraw the shapes in drawRect
        [self setContentMode:UIViewContentModeRedraw];
        
        self.xDataLable = [[NSMutableArray alloc]init];
        self.yDataLable = [[NSMutableArray alloc]init];
        self.coordinatePointsArray = [[NSMutableArray alloc]init];
        gradientMaskArray = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect
{
    //Create graph data
    [self createGraphCoordinates];
    
    //Create Graph layout
    if (self.isLayoutNeeded)
    {
        [self createGraphLayout];
    }
    
    [self drawBarGraph];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    float ix = STARTING_X;
    float iy = STARTING_Y;
    
    //Layouts for x-axis label
    for (UILabel *label in self.xDataLable)
    {
        if (ix <= (TOTAL_X_DIST + self.spacingX))
        {
            [label setFrame:CGRectMake(ix, STARTING_Y, self.spacingX, VIEW_BOUNDS_HEIGHT * 0.05)];
            label.center = CGPointMake((ix+(self.spacingX/2)), label.center.y);
            [self addSubview:label];
        }
        ix = ix + self.spacingX;
    }
    
    for (UILabel *label in self.yDataLable)
    {
        if (iy <= (TOTAL_Y_DIST + self.spacingY))
        {
            label.textAlignment = NSTextAlignmentCenter;
            [label setFrame:CGRectMake(STARTING_X - VIEW_BOUNDS_WIDTH * 0.05, iy - self.spacingY/2, VIEW_BOUNDS_WIDTH * 0.05, self.spacingY)];
            [self addSubview:label];
        }
        iy = iy - self.spacingY;
    }
}

#pragma mark - data creation methods
- (void)createGraphCoordinates
{
    self.spacingX = TOTAL_X_DIST/((self.scale.max_x - self.scale.min_x)/self.scale.x_unit);
    self.spacingY = TOTAL_Y_DIST/((self.scale.max_y - self.scale.min_y)/self.scale.y_unit);
    
    // calculating co-ordinates with respect to provided data
    for (GraphData *data in self.dataArray)
    {
        CGPoint coordinate;
        //Formula to calculate coordiante point on the screen.
        coordinate.x = (STARTING_X*self.scale.x_unit + (data.x_point * self.spacingX))/self.scale.x_unit;
        coordinate.y = (STARTING_Y*self.scale.y_unit - (data.y_point * self.spacingY))/self.scale.y_unit;
        
        [self.coordinatePointsArray addObject:[NSValue valueWithCGPoint:coordinate]];
    }
    
    [self.coordinatePointsArray removeObjectAtIndex:0];
}

#pragma  mark - graph drawing methods
- (void)createGraphLayout
{
    //Clear old graph layout
    [self.graphLayout removeFromSuperlayer];
    
    //Creating gaph layout path (Border)
    UIBezierPath *graphPath = [[UIBezierPath alloc]init];
    
    [graphPath setLineWidth:LAYOUT_BORDER_THICKNESS];
    [graphPath moveToPoint:CGPointMake(ENDING_X, STARTING_Y)];
    [graphPath addLineToPoint:CGPointMake(STARTING_X, STARTING_Y)];
    [graphPath addLineToPoint:CGPointMake(STARTING_X, ENDING_Y)];
    
    //Creating graph layout
    self.graphLayout = [[UtilityFunctions sharedUtilityFunctions] createShapeLayerWithFillColor:[UIColor clearColor] StrokeColor:GRAPH_LAYOUT_COLOR LineWidth:GRAPH_LAYOUT_LINE_THICKNESS andPathRef:[graphPath CGPath]];
    [self.layer addSublayer:self.graphLayout];
    
    //Remove old label data
    for (UILabel *label in self.xDataLable)
    {
        [label removeFromSuperview];
    }
    for (UILabel *label in self.yDataLable)
    {
        [label removeFromSuperview];
    }
    
    [self.xDataLable removeAllObjects];
    [self.yDataLable removeAllObjects];
    
    //creating x-axis data label
    for (float i = self.scale.min_x; i <= self.scale.max_x; i = i + self.scale.x_unit)
    {
        [self.xDataLable addObject:[self createGraphLayoutLabelMarkingsWithValue:i]];
    }
    
    //creating y-axis data label
    for (float i = self.scale.min_y; i <= self.scale.max_y; i = i + self.scale.y_unit)
    {
        [self.yDataLable addObject:[self createGraphLayoutLabelMarkingsWithValue:i]];
    }
}

- (UILabel *)createGraphLayoutLabelMarkingsWithValue:(float)i
{
    UILabel *marking = [[UILabel alloc] init];
    marking.textColor = GRAPH_LABEL_COLOR;
    marking.textAlignment = NSTextAlignmentLeft;
    marking.text = [NSString stringWithFormat:@"%.0f",i];
    [marking setFont:[UIFont fontWithName:GRAPH_LABEL_FONT_STYLE size:GRAPH_LABEL_FONT_SIZE]];
    return marking;
}

- (void)drawBarGraph
{
    //Clearing the old data
    [gradientMaskArray removeAllObjects];
    
    //Creating Bar graph
    for (NSValue *pointData in self.coordinatePointsArray)
    {
        UIBezierPath *barGraphPath = [[UIBezierPath alloc] init];
        [barGraphPath moveToPoint:CGPointMake([pointData CGPointValue].x, STARTING_Y)];
        [barGraphPath addLineToPoint:CGPointMake([pointData CGPointValue].x, [pointData CGPointValue].y)];
        
        CAShapeLayer *barShapeLayer = [[UtilityFunctions sharedUtilityFunctions] createShapeLayerWithFillColor:[UIColor clearColor] StrokeColor:GRAPH_LINE_COLOR LineWidth:self.spacingX/2 andPathRef:[barGraphPath CGPath]];
        [self.layer addSublayer:barShapeLayer];
        
        //Creating gradient mask
        CAShapeLayer *gradientMask = [[UtilityFunctions sharedUtilityFunctions] createShapeLayerWithFillColor:[UIColor clearColor] StrokeColor:[UIColor blackColor] LineWidth:self.spacingX/2 andPathRef:barShapeLayer.path];
        
        //Creating Gradient Color layer for grah line
        CAGradientLayer *gradientLayer = [[UtilityFunctions sharedUtilityFunctions] createGradientLayerWithStartPoint:CGPointMake(1.0,0.0) Endpoint:CGPointMake(1.0,1.0) ColorsArray:[NSArray arrayWithObjects:(id)[[UIColor greenColor] CGColor], (id)[[UIColor yellowColor] CGColor],(id)[[UIColor redColor] CGColor], nil] andFrame:CGRectMake(STARTING_X, STARTING_Y, TOTAL_X_DIST, -TOTAL_Y_DIST)];;
        [barShapeLayer setMask:gradientMask];
        [barShapeLayer addSublayer:gradientLayer];
        [gradientMaskArray addObject:gradientMask];
    }
    
    //Animating Bar graph
    [self animateBarGraph];
}

- (void)animateBarGraph
{
    for (CAShapeLayer *gradMas in gradientMaskArray)
    {
        CFTimeInterval animationDelay = ANIMATION_DURATION;
        
        //Animating the graph path
        CABasicAnimation *drawAnimation = [CABasicAnimation animationWithKeyPath:STROKE_END_KEY_PATH];
        drawAnimation.duration = animationDelay;
        drawAnimation.repeatCount = 1.0;  // Animate only once..
        
        // Animate from no part of the stroke being drawn to the entire stroke being drawn
        drawAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
        drawAnimation.toValue   = [NSNumber numberWithFloat:1.0f];
        
        // Add the animation to the graph
        [gradMas addAnimation:drawAnimation forKey:DRAW_CIRCLE_ANIM_KEY_PATH];
    }
}
@end
