# Developer Notes & Ideas

## Technical Debt
- [ ] Write more tests for the Demand model
- [ ] Add performance optimizations for large demand calculations
- [ ] Update API documentation
- [ ] Clean up old Load model references after migration

## Refactoring Opportunities
- [ ] Improve role and permissions implementation and workflow.
- [ ] Refactor projects controller with improved workflow.
- [ ] Consider extracting demand calculations into a service object
- [ ] Add type checking with Sorbet or RBS
- [ ] Implement caching for frequently accessed demand data

## Potential Features
- [ ] Add more comprehensive reporting for demand calculations
- [ ] Implement bulk import/export for demands
- [ ] Add more detailed documentation for the demand calculation formulas

## Architecture Considerations
- [ ] Evaluate if we should move to a more modular architecture
- [ ] Consider API versioning strategy
- [ ] Plan for database scaling as demand data grows

## Notes
- Keep backward compatibility during the Load → Demand transition
- Document any non-obvious electrical calculation formulas
- Consider adding performance benchmarks for critical paths
