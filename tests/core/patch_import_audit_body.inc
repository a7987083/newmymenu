// These are known-defect reproductions of the original helpers, not new parser acceptance tests.
static void verify(BOOL condition,const char *text){if(!condition){fprintf(stderr,"Patch audit changed: %s\n",text);abort();}}
int main(void){@autoreleasepool{
 uint64_t value=0;
 verify(ZNJIParseRVA(@"-1",&value)&&value==UINT64_MAX,"negative string wraps into unsigned address");
 verify(ZNJIParseRVA(@1.9,&value)&&value==1,"fractional NSNumber truncates to integer address");
 verify(ZNJIParseRVA(@YES,&value)&&value==1,"boolean NSNumber accepted as address");
 verify(ZNJIParseRVA(@"00000100",&value)&&value==64,"legacy base-zero leading-zero string is octal");
 verify([ZNJIHex(@[@1.9,@YES]) isEqual:@"0101"],"fractional/boolean bytes silently coerce");
 NSArray *root=@[@{@"offset":@"0x10",@"enabled":@"11223344"},@{@"offset":@"0x20",@"enabled":@"not-hex"}];
 NSMutableArray *found=[NSMutableArray array];ZNJIWalk(root,@"$",@"",@"",@"Imported",ZNJIAliases(root),found);
 verify(found.count==1&&[found[0][@"offset"] isEqual:@"0x10"],"invalid explicit sibling is omitted without an error channel");
 [found removeAllObjects];NSDictionary *weak=@{@"arbitrary":@"0x10",@"unrelated":@"AABBCCDD"};ZNJIWalk(weak,@"$",@"",@"",@"Imported",ZNJIAliases(weak),found);
 verify(found.count==1&&[found[0][@"confidence"] doubleValue]==0.55,"unlabelled strings can produce a low-confidence candidate");
 puts("PASS AUDIT: original negative/fractional/bool coercion, octal ambiguity, silent invalid-sibling omission and confidence-0.55 heuristic reproduced");
 puts("NOT VALIDATED: production Patch migration, target binary, workspace UI/validation/apply; old workspace does retain low-confidence/read-validation stages");
 }return 0;}
