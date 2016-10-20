# 📜&nbsp;&nbsp;DrawnTableView\_MacOS\_ObjC:

**Platform:** MacOS

**Language:** Objective-C

An NSTableView alternative with a more sensible API.

Have you ever found yourself struggling with AppKit class APIs like NSTableView, NSOutlineView, et al.? We know we have. 

When we were building the Palette window for [Producer](http://www.getproducer.com), we just needed to get the job done while being able to implement our design's slightly custom appearance and behavior. 

In the end, rather than battling NSTableView or being forced into using the Interface Builder (*shudder…*), we found it to be a lot more time-effective and all around a more pleasant experience to build a hand-drawn table view with Core Graphics. Enter `LPDrawnTableView`, a subclass of `NSScrollView`. 

![DrawnTableView](https://github.com/Lunarpad/DrawnTableView_MacOS_ObjC/raw/master/images/table.png "DrawnTableView")

DrawnTableView is still very young and hasn't seen many integrations yet, but it already supports many table view interactions such as row selection, different mouse interactions, and includes features like section headers, variable cell heights, and totally custom-drawable cells.

You can make it look as similar to MacOS as you like or theme it to your exact design specifications and have your app remain about as performant as your drawing code.

## Installation:

To install, simply download the source for this module and include `./DrawnTableView` in your Xcode project. 


## How it works:

In order to make the TableView API a little more sensible, we borrow the general concept of NSAddressPath from iOS by providing `LPAddressPath` to describe locations in the table view by section and row.

After you provide an array of arrays representing your sections of table rows, you can override a custom drawing which gets called automatically by the LPDrawnTableView machinery. This is similar to how `UITableView` will call the `-dequeueReusableCell…` method, where you typically will place your codepath to configure each cell view.

Custom drawing is done entirely in Core Graphics and there are no subviews within the table view. This tends to keep the table very performant even with complicated visuals, making `LPDrawnTableView` an interesting choice in certain circumstances.

## Usage

All you have to do is:

1. Create a subclass of `LPDrawnTableView`. This is done so you can keep your custom drawing routines encapsulated. Note: subclassing may made unnecessary in the future.

		#import "LPDrawnTableView.h"
	
		@interface LPPaletteDrawnTableView : LPDrawnTableView
		
		@end


2. Instantiate your subclass by providing an initial frame:

	    LPPaletteDrawnTableView *view = [[LPPaletteDrawnTableView alloc] initWithFrame:frame];

3. In your subclass, override the `LPDrawnTableView` method `-setup`.

		- (void)setup
		{
			[super setup]; // be sure you call on super
		}

4. Before your `-setup` override calls on `super`, define a data structure holding your table's sections and rows, and provide the data structure to the subclass. You'll also want to specify the table row cell height(s).

		- (void)setup
		{
		    self.modelObjectsByRowBySection = [self _new_modelObjectsByRowBySection];
			//
	        typeof(self) __weak weakSelf = self;
	        self.newModelObjectsByRowBySection = ^NSArray *
	        {
	            NSArray *array = weakSelf.modelObjectsByRowBySection;
	            
	            return array;
	        };
	        self.newHeightForRow = ^CGFloat(NSUInteger section, NSUInteger row)
	        {
                return 29;
	        };
			//
		    [super setup];
		}
		
		- (NSArray *)_new_modelObjectsByRowBySection
		{
		    NSMutableArray *array = [NSMutableArray new];
			// Construct an array of arrays here,
			// where each array in the top-level array
			// is a section full of rows.
			// e.g. [ [1, 2, 3], [A, B, C] ]
			//
		    return array;
		}
		
	You may also want to implement `LPDrawnTableView`'s `areEqualModelObjects_block` if your model objects do not implement `-isEqual:`.
		
	Note: The choice to implement the supply of these intial properties as blocks was made to enable the removal of the need to subclass `LPDrawnTableView`.

5. And lastly, feel free to go wild specifying how you would like each cell to be drawn by overriding the `LPDrawnTableView` method `-_subclass_drawModelObject:atAddressPath:withFrame:`. You can key off the object type or address path to change the cell drawing or to draw it as a header.
	
		- (void)_subclass_drawModelObject:(id)modelObject atAddressPath:(LPAddressPath *)path withFrame:(NSRect)rowFrame
		{
		    if ([modelObject isKindOfClass:[LPAppModulePrototype class]]) {
		        [self _drawAppModulePrototype:(LPAppModulePrototype *)modelObject inRowCellFrame:rowFrame];
		    } else if ([modelObject isKindOfClass:[LPDrawnTableHeaderCellDrawingObject class]]) {
		        [self _drawTableHeaderCellDrawingObject:(LPDrawnTableHeaderCellDrawingObject *)modelObject inHeaderFrame:rowFrame];
		    } else {
		        DDLogInfo(@"I don't know how to draw this!! %@", modelObject);
		    }
		}
			
			
		////////////////////////////////////////////////////////////////////////////////
		#pragma mark - Runtime - Imperatives - Drawing
			
		- (void)_drawAppModulePrototype:(LPAppModulePrototype *)prototype inRowCellFrame:(NSRect)rowFrame
		{
		    BOOL isSelectedRow = NO;
		    if ([self currentlySelectedRowModelObject] == prototype) {
		        isSelectedRow = YES;
		    }
		    if (isSelectedRow) {
		        [NSGraphicsContext saveGraphicsState];
		        {
		            NSRect backgroundFrame = NSMakeRect(rowFrame.origin.x, rowFrame.origin.y + 1, rowFrame.size.width, rowFrame.size.height - 1); // the 1 accounts for the preceeding cell's separator line width
		            NSBezierPath *backgroundBezierPath = [NSBezierPath bezierPathWithRect:backgroundFrame];
		            [[NSColor colorWithHexString:@"3874d6"] set];
		            [backgroundBezierPath fill];
		        }
		        [NSGraphicsContext restoreGraphicsState];
		    }
		    
		    CGFloat leftMargin = 25;
		    NSRect stringDrawingFrame = NSMakeRect(rowFrame.origin.x + leftMargin, rowFrame.origin.y + 2, rowFrame.size.width - leftMargin, rowFrame.size.height);
		    NSDictionary *stringDrawingAttributes = isSelectedRow ? self.cached_selectedRowAppModuleTitleStringAttributes : self.cached_appModuleTitleStringAttributes;
		    NSAttributedString *drawingString = [[NSAttributedString alloc] initWithString:prototype.displayNameString attributes:stringDrawingAttributes];
		    [drawingString drawInRect:stringDrawingFrame];
		}
	
		- (void)_drawTableHeaderCellDrawingObject:(LPDrawnTableHeaderCellDrawingObject *)headerCellDrawingObject inHeaderFrame:(NSRect)rowFrame
		{
		    CGFloat leftMargin = 6;
		    NSRect drawingFrame = NSMakeRect(rowFrame.origin.x + leftMargin, rowFrame.origin.y - 4, rowFrame.size.width - leftMargin, rowFrame.size.height);
		    [NSGraphicsContext saveGraphicsState];
		    {
		        if (headerCellDrawingObject.backgroundColor) {
		            [headerCellDrawingObject.backgroundColor set];
		            NSRectFill(rowFrame);
		        }
		        
		        NSBezierPath *backgroundBezierPath = [NSBezierPath bezierPathWithRect:rowFrame];
		        NSColor *startingColor;
		        NSColor *endingColor;
		        startingColor = [NSColor colorWithCalibratedWhite:0.4 alpha:1.0];
		        endingColor = [NSColor colorWithCalibratedWhite:0.6 alpha:1.0];
		        NSGradient *borderGradient = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
		        [borderGradient drawInBezierPath:backgroundBezierPath angle:-90];
		        
		        NSShadow *theShadow = [[NSShadow alloc] init];
		        [theShadow setShadowOffset:CGSizeMake(0, 1)];
		        [theShadow setShadowBlurRadius:0];
		        [theShadow setShadowColor:[NSColor colorWithWhite:0 alpha:0.2]];
		        [theShadow set];
		        
		        [headerCellDrawingObject.titleLabelAttributeString drawInRect:drawingFrame]; // Drawing twice for 'strong' effect
		    }
		    [NSGraphicsContext restoreGraphicsState];
		}

## Additional features

LPDrawnTableView comes with lots of little features that we added for our particular use-case. If you have any questions about how to use these methods or want to discover potentially undocumented features we encourage you to dive into the code to check it out. Please feel free to add anything that you see fit. We'd love to receive pull requests and will definitely credit you here if we merge your submission.

`LPDrawnTableView.h` exposes lots of properties available at runtime, such as:

	- (NSArray *)modelObjectsByRowBySection;
	- (id)modelObjectAtAddressPath:(LPAddressPath *)addressPath;
	- (id)modelObjectWithIsEqualBlock:(BOOL(^)(id modelObject))block; // supply your own block to check for equality
	
	- (LPAddressPath *)addressPathOfModelObject:(id)modelObject;
	
	- (CGFloat)currentTotalScrollHeight;
	- (LPAddressPath *)currentlySelectedRowAddressPath;
	- (id)currentlySelectedRowModelObject;
	- (LPDrawnTableDocumentView *)tableDocumentView;

… as well as lots of imperative methods for tasks like programmatically selecting, scrolling, and reloading the table:

	- (void)reload; // called at -setup if self.newModelObjectsByRowBySection already set…… i.e. by a subclass
	
	- (void)reload_withoutRedrawing;
	
	- (void)reload_nonMainThreadAspects_withoutRedrawing;
	- (void)reload_mainThreadAspects_withoutRedrawing;
	
	- (void)redraw;
	
	- (void)selectFirstRow;
	- (void)reselectPreviouslySelectedModelObjectIfStillPresent_orSelectFirstRow:(id)previouslySelected_modelObject;

In order to be notified of events and interactions which are occurring on the table view, you can subscribe by implementing the following optional blocks:

	@property (nonatomic, copy) void(^selectedRow)(id modelObject, LPAddressPath *addressPath);
	@property (nonatomic, copy) void(^doubleClickedRow)(id modelObject, LPAddressPath *addressPath);
	
## Examples

To see a full implementation example, check out `examples/LPPaletteModulesDrawnTableView` and its consumer/controller `LPPaletteWindowContentViewClipView`. This example demonstrates how to add a search field, controlling cell selection state, scrolling, and basic drawing.
