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
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    self.view.backgroundColor = _chart.backgroundColor;
        
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
    lineSeries.crosshairEnabled = YES;
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
