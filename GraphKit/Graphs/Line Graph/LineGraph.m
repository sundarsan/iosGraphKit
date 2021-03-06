//
//  LineGraph.m
//  GraphKit
//
//  Created by Sunil Rao on 26/04/16.
//  Copyright © 2016 Sunil Rao. All rights reserved.
//

#import "LineGraph.h"

#define GRAPH_POINT_DIA     TOTAL_X_DIST * 0.03

@interface LineGraph()

@property (nonatomic,strong) NSArray *dataArray;
@property (nonatomic,strong) GraphScale *scale;
@property (nonatomic,strong) NSMutableArray *coordinatePointsArray;
@property (nonatomic) BOOL isLayoutNeeded;
@property (nonatomic,assign) float spacingX;
@property (nonatomic,assign) float spacingY;
@property (nonatomic,strong)NSMutableArray *xDataLable;
@property (nonatomic,strong)NSMutableArray *yDataLable;
@property (nonatomic,strong) CAShapeLayer *graphLayout;
@property (nonatomic,strong) UILabel *xAxisTitleLabel, *yAxisTitleLabel;
@property (nonnull,strong) UIView *graphPoint;
@property (nonatomic,strong) CAShapeLayer *gradientMask;
@property (nonatomic,strong) CAGradientLayer *gradientLayer;

@end

@implementation LineGraph

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
    
    [self drawLineGraph];
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
    
    [self.gradientLayer setFrame:CGRectMake(STARTING_X, ENDING_Y, TOTAL_X_DIST, TOTAL_Y_DIST)];
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
//    [graphPath addLineToPoint:CGPointMake(STARTING_X, ENDING_Y)];
    
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
//    for (float i = self.scale.min_y; i <= self.scale.max_y; i = i + self.scale.y_unit)
//    {
//        [self.yDataLable addObject:[self createGraphLayoutLabelMarkingsWithValue:i]];
//    }
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

- (void)drawLineGraph
{
    //creating graph path
    UIBezierPath *graph = [[UIBezierPath alloc]init];
    [graph setLineWidth:GRAPH_LINE_WIDTH];
    [GRAPH_LINE_COLOR setStroke];
    [graph moveToPoint:[[self.coordinatePointsArray objectAtIndex:0] CGPointValue]];

    
    for (NSUInteger i=0 ; i < [self.coordinatePointsArray count]; i++)
    {
        [graph addLineToPoint:[[self.coordinatePointsArray objectAtIndex:i] CGPointValue]];
    }
    
    //Drawing Line graph with Gradient mask
    
    //drawing graph
    CAShapeLayer *graphLine = [[UtilityFunctions sharedUtilityFunctions] createShapeLayerWithFillColor:[UIColor clearColor] StrokeColor:GRAPH_LINE_COLOR LineWidth:GRAPH_LINE_WIDTH andPathRef:[graph CGPath]];
    [self.layer addSublayer:graphLine];
    
    //Creating gradient mask
    self.gradientMask = [[UtilityFunctions sharedUtilityFunctions] createShapeLayerWithFillColor:[UIColor clearColor] StrokeColor:[UIColor blackColor] LineWidth:GRAPH_LINE_WIDTH andPathRef:graphLine.path];
    self.gradientMask.path = graphLine.path;
    
    //Creating Gradient Color layer for grah line
    self.gradientLayer = [[UtilityFunctions sharedUtilityFunctions] createGradientLayerWithStartPoint:CGPointMake(1.0,0.0) Endpoint:CGPointMake(1.0,1.0) ColorsArray:[NSArray arrayWithObjects:(id)[[UIColor redColor] CGColor], [(id)[UIColor blueColor] CGColor], nil] andFrame:CGRectZero];
    [graphLine setMask:self.gradientMask];
    [graphLine addSublayer:self.gradientLayer];
    
    //Animating line graph
    [self animateLineGraph];
}

- (void)animateLineGraph
{
    //constants
    CFTimeInterval animationDelay = ANIMATION_DURATION;
    
    //Animating the graph path
    CABasicAnimation *drawAnimation = [CABasicAnimation animationWithKeyPath:STROKE_END_KEY_PATH];
    drawAnimation.duration = animationDelay;
    drawAnimation.repeatCount = 1.0;  // Animate only once..
    
    // Animate from no part of the stroke being drawn to the entire stroke being drawn
    drawAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    drawAnimation.toValue   = [NSNumber numberWithFloat:1.0f];
    
    // Add the animation to the graph
    [self.gradientMask addAnimation:drawAnimation forKey:DRAW_CIRCLE_ANIM_KEY_PATH];

}
@end
