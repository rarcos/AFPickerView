//
//  AFPickerView.m
//  PickerView
//
//  Created by Fraerman Arkady on 24.11.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AFPickerView.h"

@implementation AFPickerView
{
    float rowHeight;
    float prefixHeight;
}
#pragma mark - Synthesization

@synthesize dataSource;
@synthesize delegate;
@synthesize selectedRow = currentRow;
@synthesize rowFont = _rowFont;
@synthesize rowIndent = _rowIndent;




#pragma mark - Custom getters/setters

- (void)setSelectedRow:(int)selectedRow
{
    if (selectedRow >= rowsCount)
        return;
    
    currentRow = selectedRow;
    [contentView setContentOffset:CGPointMake(0.0, rowHeight * currentRow) animated:NO];
}




- (void)setRowFont:(UIFont *)rowFont
{
    _rowFont = rowFont;
    
    for (UILabel *aLabel in visibleViews) 
    {
        aLabel.font = _rowFont;
    }
    
    for (UILabel *aLabel in recycledViews) 
    {
        aLabel.font = _rowFont;
    }
}




- (void)setRowIndent:(CGFloat)rowIndent
{
    _rowIndent = rowIndent;
    
    for (UILabel *aLabel in visibleViews) 
    {
        CGRect frame = aLabel.frame;
        frame.origin.x = _rowIndent;
        frame.size.width = self.frame.size.width - _rowIndent;
        aLabel.frame = frame;
    }
    
    for (UILabel *aLabel in recycledViews) 
    {
        CGRect frame = aLabel.frame;
        frame.origin.x = _rowIndent;
        frame.size.width = self.frame.size.width - _rowIndent;
        aLabel.frame = frame;
    }
}




#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        
        // setup
        [self setup];
        
        prefixHeight = ceil((frame.size.height - rowHeight) / 2);
        
        // backgound
        UIImage *backgroundImage = [UIImage imageNamed:@"pickerBackground.png"];
        UIImageView *bacground = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        bacground.image = backgroundImage;
        [self addSubview:bacground];
        
        // content
        contentView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        contentView.showsHorizontalScrollIndicator = NO;
        contentView.showsVerticalScrollIndicator = NO;
        contentView.delegate = self;
        [self addSubview:contentView];
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
        [contentView addGestureRecognizer:tapRecognizer];
        
        
        // shadows
        UIImage *shadowsImage = [UIImage imageNamed:@"pickerShadows.png"];
        UIImageView *shadows = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        shadows.image = shadowsImage;
        [self addSubview:shadows];
        
        // glass
        UIImage *glassImage = [UIImage imageNamed:@"pickerGlass.png"];
        glassImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, prefixHeight, frame.size.width, rowHeight)];
        glassImageView.image = glassImage;
        [self addSubview:glassImageView];
    }
    return self;
}




- (void)setup
{
    _rowFont = [UIFont boldSystemFontOfSize:24.0];
    _rowIndent = 30.0;
    
    rowHeight = 20.0;
    
    currentRow = 0;
    rowsCount = 0;
    visibleViews = [[NSMutableSet alloc] init];
    recycledViews = [[NSMutableSet alloc] init];
}




#pragma mark - Buisness

- (void)reloadData
{
    // empry views
    currentRow = 0;
    rowsCount = 0;
    
    for (UIView *aView in visibleViews) 
        [aView removeFromSuperview];
    
    for (UIView *aView in recycledViews)
        [aView removeFromSuperview];
    
    visibleViews = [[NSMutableSet alloc] init];
    recycledViews = [[NSMutableSet alloc] init];
    
    rowsCount = [dataSource numberOfRowsInPickerView:self];
    [contentView setContentOffset:CGPointMake(0.0, 0.0) animated:NO];
    contentView.contentSize = CGSizeMake(contentView.frame.size.width, rowHeight * rowsCount + 2 * prefixHeight);    
    [self tileViews];
}




- (void)determineCurrentRow
{
    CGFloat delta = contentView.contentOffset.y;
    int position = round(delta / rowHeight);
    currentRow = position;
    [contentView setContentOffset:CGPointMake(0.0, rowHeight * position) animated:YES];
    [delegate pickerView:self didSelectRow:currentRow];
}




- (void)didTap:(id)sender
{
    UITapGestureRecognizer *tapRecognizer = (UITapGestureRecognizer *)sender;
    CGPoint point = [tapRecognizer locationInView:self];
    
    float steps = ((point.y - prefixHeight) / rowHeight);
    if (steps >= 0) {
        [self makeSteps:-floor(steps)];
    } else {
        [self makeSteps:-floor(steps)];
    }
}




- (void)makeSteps:(int)steps
{
    if (steps == 0 || steps > ceil(prefixHeight / rowHeight)|| steps < -ceil(prefixHeight / rowHeight))
        return;
    
    [contentView setContentOffset:CGPointMake(0.0, rowHeight * currentRow) animated:NO];
    
    int newRow = currentRow + steps;
    if (newRow >= rowsCount)
    {
        [self makeSteps:(newRow - rowsCount)];
        return;
    } 
    else if (newRow < 0) 
    {
        [self makeSteps:(steps - newRow)];
        return;
    }
    
    currentRow = currentRow + steps;
    [contentView setContentOffset:CGPointMake(0.0, rowHeight * currentRow) animated:YES];
    [delegate pickerView:self didSelectRow:currentRow];
}




#pragma mark - recycle queue

- (UIView *)dequeueRecycledView
{
	UIView *aView = [recycledViews anyObject];
	
    if (aView) 
        [recycledViews removeObject:aView];
    return aView;
}



- (BOOL)isDisplayingViewForIndex:(NSUInteger)index
{
	BOOL foundPage = NO;
    for (UIView *aView in visibleViews) 
	{
        int viewIndex = ceil(aView.frame.origin.y / rowHeight) - ceilf(prefixHeight / rowHeight);
        if (viewIndex == index) 
		{
            foundPage = YES;
            break;
        }
    }
    return foundPage;
}




- (void)tileViews
{
    // Calculate which pages are visible
    CGRect visibleBounds = contentView.bounds;
    int firstNeededViewIndex = floorf(CGRectGetMinY(visibleBounds) / rowHeight) - ceil(prefixHeight / rowHeight);
    int lastNeededViewIndex  = floorf((CGRectGetMaxY(visibleBounds) / rowHeight)) - ceil(prefixHeight / rowHeight);
    firstNeededViewIndex = MAX(firstNeededViewIndex, 0);
    lastNeededViewIndex  = MIN(lastNeededViewIndex, rowsCount - 1);
	
    // Recycle no-longer-visible pages 
	for (UIView *aView in visibleViews) 
    {
        int viewIndex = ceil(aView.frame.origin.y / rowHeight) - ceil(prefixHeight / rowHeight);
        if (viewIndex < firstNeededViewIndex || viewIndex > lastNeededViewIndex) 
        {
            [recycledViews addObject:aView];
            [aView removeFromSuperview];
        }
    }
    
    [visibleViews minusSet:recycledViews];
    
    // add missing pages
	for (int index = firstNeededViewIndex; index <= lastNeededViewIndex; index++) 
	{
        if (![self isDisplayingViewForIndex:index]) 
		{
            UILabel *label = (UILabel *)[self dequeueRecycledView];
            
			if (label == nil)
            {
				label = [[UILabel alloc] initWithFrame:CGRectMake(_rowIndent, 0, self.frame.size.width - _rowIndent, rowHeight)];
                label.backgroundColor = [UIColor clearColor];
                label.font = self.rowFont;
                label.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.75];
                label.textAlignment = UITextAlignmentCenter;
            }
            
            [self configureView:label atIndex:index];
            [contentView addSubview:label];
            [visibleViews addObject:label];
        }
    }
}




- (void)configureView:(UIView *)view atIndex:(NSUInteger)index
{
    UILabel *label = (UILabel *)view;
    label.text = [dataSource pickerView:self titleForRow:index];
    CGRect frame = label.frame;
    frame.origin.y = rowHeight * index + prefixHeight;
    label.frame = frame;
}




#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self tileViews];
}




- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
        [self determineCurrentRow];
}




- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self determineCurrentRow];
}

@end
