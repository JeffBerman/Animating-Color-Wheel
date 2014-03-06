//
//  ColorWheelView.m
//  radial
//
//  Created by Chris DeSalvo on 3/5/14.
//  This work is dedicated to the public domain
//

#import "ColorWheelView.h"

@interface ColorWheelView ()

//  This determines how many wedges make up the color wheel. The higher the number the smoother
//  the color gradients will be, but the more expensive it'll be to draw.
@property (nonatomic, assign)   double          numSectors;
@property (nonatomic, strong)   NSBezierPath    *wedgePath;
@property (nonatomic, assign)   double          wheelRadius;
@property (nonatomic, assign)   CGPoint         viewCenter;
@property (nonatomic, assign)   double          startAngle;

@property (nonatomic, strong)   NSTimer         *rotationTimer;

@end

@implementation ColorWheelView

- (void)awakeFromNib
{
    self.wantsLayer = YES;
    self.layer.backgroundColor = [NSColor blackColor].CGColor;

    self.numSectors = 50;
    [self frameDidChange:nil];

    //  We want to be notified any time that our frame changes so that we can rebuild the wedge prototype
    NSNotificationCenter    *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self selector:@selector(frameDidChange:)
               name:NSViewFrameDidChangeNotification
             object:self];
}

- (void)dealloc
{
    NSNotificationCenter    *nc = [NSNotificationCenter defaultCenter];

    [nc removeObserver:self];
}

- (void)frameDidChange:(NSNotification *)note
{
    [self recalculatePath];
}

- (IBAction)sectorCountChanged:(id)sender
{
    self.numSectors = [sender doubleValue];

    [self recalculatePath];
}

- (void)recalculatePath
{
    //  Each color band will cover this many degrees of arc
    double  theta = 360.0 / self.numSectors;

    //  Find the center of our view and the radius of our circle
    self.viewCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    self.wheelRadius = MIN(self.viewCenter.x, self.viewCenter.y) - 5;

    //  Core Graphics points are placed at the center of a pixel and extend out for half a pixel
    //  in each direction. Since we're stroking the weges with a 1 pixel line we need to back off
    //  half a pixel on the apex position so that all the wedge corners meet in the middle instead
    //  of the last one slightly overwriting all of the others.
    CGPoint apex = CGPointMake(0.0, 0.5);

    //  Make a wedge-shaped path to act as the template for all drawing
    self.wedgePath = [NSBezierPath bezierPath];

    [self.wedgePath appendBezierPathWithArcWithCenter:apex radius:self.wheelRadius startAngle:0.0 endAngle:theta];
    [self.wedgePath lineToPoint:apex];
    [self.wedgePath closePath];

    //  NB: if you really wanted to speed things up you'd draw the color wheel once and then save
    //      it as a bitmap. Then the drawing loop would just be a single context rotation and a
    //      bitmap blit.
}

- (void)viewDidMoveToSuperview
{
    if (self.superview)
    {
        self.rotationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 30.0     //  30 fps
                                                              target:self
                                                            selector:@selector(tick)
                                                            userInfo:nil
                                                             repeats:YES];
    }
    else
    {
        if ([self.rotationTimer isValid])
        {
            [self.rotationTimer invalidate];
            self.rotationTimer = nil;
        }
    }
}

- (void)tick
{
    //  Core Graphics has positive rotation going counter-clockwise. I wanted things to go
    //  clockwise which is why this is negative.
    self.startAngle -= .05;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    //  Grab the current graphics context
    CGContextRef    c = [[NSGraphicsContext currentContext] graphicsPort];

    //  Although the NS classes use degrees the CG classes use radians
    double          thetaRadians = 2.0 * M_PI / self.numSectors;

    //  Since we're sweeping arcs it is helpful to move (0, 0) to the center of our view
    CGContextTranslateCTM(c, self.viewCenter.x, self.viewCenter.y);

    //  This sets the initial rotation for drawing. This is how the animation is achieved.
    CGContextRotateCTM(c, self.startAngle);

    //  Finally, the drawing loop
    for (NSUInteger i = 0; i < ceil(self.numSectors); i++)
    {
        //  Select the color for this slice
        NSColor *color = [NSColor colorWithCalibratedHue:(double) i / self.numSectors saturation:1.0 brightness:1.0 alpha:1.0];

        [color set];

        //  Draw it
        [self.wedgePath fill];
        [self.wedgePath stroke];

        //  Rotate the world so that we're ready for the next one
        CGContextRotateCTM(c, thetaRadians);
    }
}

@end
