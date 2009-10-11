
#import "SampleCatalogViewController.h"
#import "TrivialScrollingViewController.h"
#import "TrivialZoomingViewController.h"
#import "TrivialCircleZoomingViewController.h"
#import "ExemplaryPagingViewController.h"
#import "ExemplaryCircleZoomingViewController.h"
#import "PageLoopViewController.h"
#import "PagingAndZoomingViewController.h"


@interface Sample : NSObject {
	Class _klass;
	NSString *_name;
	NSString *_description;
}

@property(nonatomic, assign) Class klass;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *description;

+ (Sample *)sampleWithKlass:(Class)klass name:(NSString *)name description:(NSString *)description;

@end


@implementation Sample

@synthesize klass=_klass, name=_name, description=_description;

+ (Sample *)sampleWithKlass:(Class)klass name:(NSString *)name description:(NSString *)description {
	Sample *sample = [[[Sample alloc] init] autorelease];
	sample.klass = klass;
	sample.name = name;
	sample.description = description;
	return sample;
}

@end


@interface Section : NSObject {
	NSString *_name;
	NSArray *_items;
}

@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSArray *items;

+ (Section *)sectionNamed:(NSString *)name items:(NSArray *)items;

@end


@implementation Section

@synthesize name=_name, items=_items;

+ (Section *)sectionNamed:(NSString *)name items:(NSArray *)items {
	Section *section = [[[Section alloc] init] autorelease];
	section.name = name;
	section.items = items;
	return section;
}

@end



@interface SampleCatalogViewController ()

@property(nonatomic, retain) NSArray *sections;

@end


@implementation SampleCatalogViewController

@synthesize sections=_sections;

- (void)dealloc {
	self.sections = nil;
    [super dealloc];
}

- (void)viewDidLoad {
	self.sections = [NSArray arrayWithObjects:
					 [Section sectionNamed:@"Trivial"
									 items:[NSArray arrayWithObjects:
											[Sample sampleWithKlass:[TrivialScrollingViewController class] name:@"Scrolling" description:@"UIImageView inside UIScrollView"],
											[Sample sampleWithKlass:[TrivialZoomingViewController class] name:@"Zooming" description:@"1 UIImageView, 1 UIScrollView, zoom 0.1–1.0"],
											[Sample sampleWithKlass:[TrivialCircleZoomingViewController class] name:@"Naïve Circle Zooming" description:@"Scaled vector graphics is pixelated"],
											nil]],
					 [Section sectionNamed:@"Exemplary"
									 items:[NSArray arrayWithObjects:
											[Sample sampleWithKlass:[ExemplaryPagingViewController class] name:@"Paging" description:@"Lazy loading, rotation"],
											[Sample sampleWithKlass:[ExemplaryCircleZoomingViewController class] name:@"Smart Circle Zooming" description:@"Look, ma, no pixelation!"],
											nil]],
					 [Section sectionNamed:@"Tricks"
									 items:[NSArray arrayWithObjects:
											[Sample sampleWithKlass:[PageLoopViewController class] name:@"Page Loop" description:@"3 images paged in a cycle"],
											[Sample sampleWithKlass:[PagingAndZoomingViewController class] name:@"Paging + Pinch Zooming" description:@"…with a single UIScrollView"],
											nil]],
//					 [Section sectionNamed:@"ZoomScrollView"
//									 items:[NSArray arrayWithObjects:
//											[Sample sampleWithKlass:[ScrollingMadnessViewController class] name:@"ZoomScrollView demo" description:@"Paging + zooming"],
//											nil]],
					 nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	self.sections = nil;
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionNo {
	Section *section = [self.sections objectAtIndex:sectionNo];
    return [section.items count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionNo {
	Section *section = [self.sections objectAtIndex:sectionNo];
	return section.name;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
	Section *section = [self.sections objectAtIndex:indexPath.section];
    Sample *sample = [section.items objectAtIndex:indexPath.row];
	cell.textLabel.text = sample.name;
	cell.detailTextLabel.text = sample.description;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	Section *section = [self.sections objectAtIndex:indexPath.section];
    Sample *sample = [section.items objectAtIndex:indexPath.row];
	UIViewController *vc = [[[sample.klass alloc] init] autorelease];
	[self.navigationController pushViewController:vc animated:YES];
}

@end

