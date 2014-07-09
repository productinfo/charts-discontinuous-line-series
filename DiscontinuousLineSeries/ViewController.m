//
//  ViewController.m
//  AddingAnnotations
//
//  Copyright 2012 Scott Logic
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ViewController.h"
#import <ShinobiCharts/ShinobiCharts.h>

@interface ViewController () <SChartDatasource, SChartDelegate>

@end

@implementation ViewController
{
    ShinobiChart* _chart;
    NSMutableArray* _timeSeries;
    BOOL _firstChartRender;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _firstChartRender = YES;
    
    // Create the chart
    self.view.backgroundColor = [UIColor whiteColor];
    CGFloat margin = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? 10.0 : 50.0;
    _chart = [[ShinobiChart alloc] initWithFrame:CGRectInset(self.view.bounds, margin, margin)];
    _chart.title = @"Apple Stock Price";
    
    _chart.autoresizingMask =  ~UIViewAutoresizingNone;
    
    _chart.licenseKey = @""; // TODO: add your trial licence key here!
    
    // add the axes
    SChartDateTimeAxis *xAxis = [[SChartDateTimeAxis alloc] init];
    xAxis.title = @"Date";
    _chart.xAxis = xAxis;    
    SChartNumberAxis *yAxis = [[SChartNumberAxis alloc] init];
    yAxis.title = @"Price (USD)";
    _chart.yAxis = yAxis;
    
    // create some data
    [self loadChartData];
    
    // enable gestures
    [self enablePanAndZoom:xAxis];
    [self enablePanAndZoom:yAxis];
    
    // add to the view
    [self.view addSubview:_chart];
    
    _chart.datasource = self;
    _chart.delegate = self;
        
}

- (void)enablePanAndZoom:(SChartAxis*)axis {
    axis.enableMomentumPanning = YES;
    axis.enableMomentumZooming = YES;
    axis.enableGestureZooming = YES;
    axis.enableGesturePanning = YES;
}

- (void)loadChartData {
    
    _timeSeries = [NSMutableArray new];
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"AppleStockPrices" ofType:@"json"];
    NSData* json = [NSData dataWithContentsOfFile:filePath];
    NSArray* data = [NSJSONSerialization JSONObjectWithData:json
                                                    options:NSJSONReadingAllowFragments
                                                      error:nil];
    
    for (NSDictionary* jsonPoint  in data) {
        SChartDataPoint* datapoint = [self dataPointForDate:jsonPoint[@"date"]
                                                   andValue:jsonPoint[@"close"]];
        [_timeSeries addObject:datapoint];
    }
    
}


// adds date-markers to the chart
- (void)addDateMarkerAnnotations {
    // read the annotations from a JSON file
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"Annotations" ofType:@"json"];
    NSData* json = [NSData dataWithContentsOfFile:filePath];
    NSArray* data = [NSJSONSerialization JSONObjectWithData:json
                                                    options:NSJSONReadingAllowFragments
                                                      error:nil];
    
    // create a line and text annotation for each 'date' marker on the chart
    CGAffineTransform rotationTransform = CGAffineTransformRotate(CGAffineTransformIdentity, -M_PI/2);
    for (NSDictionary* jsonPoint in data) {
        
        // extract the data for this annotation
        NSDate* date = [self dateFromString:jsonPoint[@"date"]];
        NSNumber* yValue = jsonPoint[@"y-location"];
        NSString* text = jsonPoint[@"annotation"];
        
        // add a vertical line annotation
        SChartAnnotation *releaseAnnotation = [SChartAnnotation verticalLineAtPosition:date
                                                                             withXAxis:_chart.xAxis
                                                                              andYAxis:_chart.yAxis
                                                                             withWidth:2.f
                                                                             withColor:[UIColor colorWithWhite:0.7 alpha:1.0]];
        releaseAnnotation.position = SChartAnnotationAboveData;
        [_chart addAnnotation:releaseAnnotation];
        
        // add a text annotation
        SChartAnnotation *releaseLabel = [SChartAnnotation annotationWithText:text
                                                                      andFont:[UIFont systemFontOfSize:14.f]
                                                                    withXAxis:_chart.xAxis
                                                                     andYAxis:_chart.yAxis
                                                                  atXPosition:date
                                                                 andYPosition:yValue
                                                                withTextColor:[UIColor blackColor]
                                                          withBackgroundColor:_chart.plotAreaBackgroundColor];

        // rotate the text by 90 degrees
        releaseLabel.transform = rotationTransform;
        releaseLabel.position = SChartAnnotationAboveData;
        [_chart addAnnotation:releaseLabel];
    }
}

-(void)addCustomAnnotation {
    
    // create an annotation
    SChartAnnotationZooming* an = [[SChartAnnotationZooming alloc] init];
    an.xAxis = _chart.xAxis;
    an.yAxis = _chart.yAxis;
    
    // set its location - using the data coordinate system
    an.xValue = [self dateFromString:@"01-01-2009"];
    an.yValue = @250;
    
    // pin all four corners of the annotation so that it stretches
    an.xValueMax = [self dateFromString:@"01-01-2011"];
    an.yValueMax = @550;
    
    // set bounds
    an.bounds = CGRectMake(0,0,50,50);
    an.position = SChartAnnotationBelowData;
    
    // Add some custom content to the annotation
    UIImage* image = [UIImage imageNamed:@"Apple.png"];
    UIImageView* imageView = [[UIImageView alloc] initWithImage:image];
    imageView.alpha = 0.1f;
    [an addSubview:imageView];
    
    // add to the chart
    [_chart addAnnotation:an];
}

- (void)sChartRenderFinished:(ShinobiChart *)chart {
    if (_firstChartRender) {
        _firstChartRender = NO;
        
        [self addDateMarkerAnnotations];
        [self addCustomAnnotation];
    }
}

#pragma mark - utility methods

- (NSDate*) dateFromString:(NSString*)date {
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    }
    return [dateFormatter dateFromString:date];
}

- (SChartDataPoint*)dataPointForDate:(NSString*)date andValue:(NSNumber*)value {
    SChartDataPoint* dataPoint = [SChartDataPoint new];
    dataPoint.xValue = [self dateFromString:date];
    dataPoint.yValue = value;
    return dataPoint;
}

- (BOOL) isDate:(NSDate*)date inRangeWithLowerBound:(NSDate*)lowerBound upperBound:(NSDate*)upperBound {
    return [date compare:lowerBound] == NSOrderedDescending
    && [date compare:upperBound] == NSOrderedAscending;
}

#pragma mark - SChartDatasource methods

- (NSInteger)numberOfSeriesInSChart:(ShinobiChart *)chart {
    return 1;
}

-(SChartSeries *)sChart:(ShinobiChart *)chart seriesAtIndex:(NSInteger)index {
    SChartLineSeries *lineSeries = [[SChartLineSeries alloc] init];
    return lineSeries;
}

- (NSInteger)sChart:(ShinobiChart *)chart numberOfDataPointsForSeriesAtIndex:(NSInteger)seriesIndex {
    return _timeSeries.count;
}

- (id<SChartData>)sChart:(ShinobiChart *)chart dataPointAtIndex:(NSInteger)dataIndex forSeriesAtIndex:(NSInteger)seriesIndex {
    SChartDataPoint *dataPoint = _timeSeries[dataIndex];
    
    NSDate *lowerBound = [self dateFromString:@"01-01-2009"];
    NSDate *upperBound = [self dateFromString:@"01-01-2010"];
    
    if ([self isDate:dataPoint.xValue inRangeWithLowerBound:lowerBound upperBound:upperBound]) {
        //then we want a gap, so nil the y value
        dataPoint.yValue = nil;
    }
    
    return dataPoint;
}

@end
