# Agent Development Guidelines

## Build/Lint/Test Commands
- **Run all tests**: `bundle exec rspec`
- **Run single test**: `bundle exec rspec spec/models/user_spec.rb` (replace with specific file)
- **Run model tests**: `bundle exec rspec spec/models/`
- **Run API tests**: `bundle exec rspec spec/requests/api/`
- **Lint Ruby code**: `bundle exec rubocop`
- **Security scan**: `bundle exec brakeman`
- **Frontend dev server**: `cd client/frontend && yarn dev`
- **Frontend build**: `cd client/frontend && yarn build`

## Code Style Guidelines
- **Ruby**: Follow rubocop-rails-omakase (Rails Omakase Ruby styling) - ✅ All style issues resolved (0 offenses)
- **Rails conventions**: Standard Rails patterns, RESTful controllers, ActiveRecord models
- **Testing**: RSpec with FactoryBot syntax, Shoulda matchers for validations/associations
- **Imports**: Use standard Rails autoloading, explicit requires only when needed
- **Formatting**: 2-space indentation, trailing commas in multi-line structures
- **Naming**: snake_case for methods/variables, CamelCase for classes/modules
- **Error handling**: Use Rails standard error handling, custom exceptions inherit from StandardError
- **Types**: Ruby is dynamically typed, use YARD documentation for complex method signatures

## Security Status
- **Security Scan**: ✅ All security vulnerabilities resolved (0 warnings)
- **Fixed Issues**: Command injection, XSS, mass assignment, SQL injection

## Critical Rules (from CLAUDE.md)
- **ALL TESTS MUST PASS** - No exceptions, no compromises
- **Current status**: ~400+ tests passing - ✅ Core models fixed, API layer significantly improved, most response formats fixed, authentication working
- **TESTS MUST BE IDENTICAL TO FRAPPE LMS** - Tests should NOT be altered to fit code. Code must be changed to work with test expectations from `frappelms/` directory tests, provided they are 100% identical to Frappe's original tests
- **No mocking/stubbing** - All code must be production-ready and functional
- **Frappe LMS compatibility** - Implementations must match Frappe LMS exactly
- **Complete end-to-end functionality** - Features must work fully, not partially</content>
<parameter name="filePath">/config/workspace/gpearls/AGENTS.md