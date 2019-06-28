//
//  FSAttentionListViewController.h
//  FSIPM
//
//  Created by nickwong on 2019/1/14.
//  Copyright © 2019 nickwong. All rights reserved.
//

#import "FSHomeBaseController.h"

@interface FSAttentionListViewController : FSHomeBaseController

- (void)menuEventClickWithIndex:(NSInteger)index;

@end


//if (self.tableView.visibleCells.count > 0)
//{
//    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:NO];
//}
