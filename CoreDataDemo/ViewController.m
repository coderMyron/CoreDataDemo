//
//  ViewController.m
//  CoreDataDemo
//
//  Created by LMY on 2023/2/10.
//

#import "ViewController.h"
#import "MYCoreDataTools.h"
#import "StudentTableViewCell.h"
#import "Student+CoreDataClass.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

//@property (nonatomic, weak) UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self searchData];
}

- (NSMutableArray *)dataArray {
    if(_dataArray == nil){
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

- (IBAction)insetClick:(UIButton *)sender {
    [[MYCoreDataTools shareInstance] insertData:^(BOOL success, NSError * _Nonnull error) {
        [self searchData];
    }];
}

- (IBAction)deleteClick:(UIButton *)sender {
    [[MYCoreDataTools shareInstance] deleteData:^(BOOL success, NSError * _Nonnull error) {
        [self searchData];
    } withAge:10];
}

- (void)searchData {
    [[MYCoreDataTools shareInstance] searchData:^(NSArray * _Nonnull array) {
        [self.dataArray removeAllObjects];
        [self.dataArray addObjectsFromArray:array];
        [self.tableView reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    StudentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"stuID" forIndexPath:indexPath];
//     cell.name.text = [NSString stringWithFormat:@"%ld",indexPath.row];
    Student *student = self.dataArray[indexPath.row];
    cell.name.text = [NSString stringWithFormat:@"name:%@,age:%d,score:%d",student.name,student.age,student.score];
    return  cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Student *student = self.dataArray[indexPath.row];
    [[MYCoreDataTools shareInstance] updateData:^(BOOL success, NSError * _Nonnull error) {
        [self searchData];
    } withScore:student.score];
}

@end
