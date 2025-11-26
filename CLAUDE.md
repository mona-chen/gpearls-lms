# CLAUDE AI DEVELOPMENT RULES

## PRIMARY DIRECTIVE
**ALL TESTS MUST PASS - NO EXCEPTIONS**

This is the highest priority rule. Every single test in the system must pass, regardless of complexity, time, or difficulty. There are no "nice-to-have" features - everything is critical.

## TEST PASS RATE REQUIREMENTS
- **Target**: 100% pass rate (0 failures, 0 errors)
- **Current Status**: 498/1044 tests passing (47.7%)
- **Remaining**: 546 tests to fix
- **Deadline**: All tests passing before any feature is considered complete

## CRITICAL FEATURES (USP - Unique Selling Proposition)
The following features are NOT optional and must work 100%:
- ✅ SCORM Package Management (51/51 tests - COMPLETED)
- ✅ SCORM Completion Tracking (27/27 tests - COMPLETED)
- ✅ Code Revision System (15/15 tests - COMPLETED)
- ✅ Batch Management (35/35 tests - COMPLETED)
- ✅ Core Models (Course, Enrollment, User, LmsQuestion - 140/140 tests - COMPLETED)
- LmsQuiz System (22 tests - Complex model conflicts need resolution)

## DEVELOPMENT APPROACH
1. **No Compromises**: Every failing test must be fixed
2. **Complete Implementation**: Features must work end-to-end
3. **Frappe Compatibility**: All implementations must match Frappe LMS exactly
4. **Test Coverage**: 100% test pass rate required
5. **No Mocking**: This is a production system. All implementations must be real, functional code. No dummy responses, stubs, or mocks allowed. Every feature must work in production.

## RECENT PROGRESS
- ✅ **ScormPackage Model**: 51/51 tests passing - Full SCORM package extraction, manifest parsing, security checks, and file handling
- ✅ **ScormCompletion Model**: 27/27 tests passing - Complete SCORM progress tracking, data mapping, and analytics
- ✅ **CodeRevision Model**: 15/15 tests passing - Complete polymorphic code revision system with auto-save functionality
- ✅ **Batch Model**: 35/35 tests passing - Complete batch management with enrollment, scheduling, and Frappe-compatible slug generation
- ✅ **Core Models**: Course (40), Enrollment (25), User (57), LmsQuestion (18), VideoWatchDuration (21) - 161 tests passing
- **Total Fixed**: 289 tests now passing across critical LMS systems

## MEASUREMENT
- Daily progress reports on test pass rate
- No feature acceptance until all tests pass
- Regression testing for all changes

**RULE: If any test fails, the system is not ready. Period.**

**CURRENT ACHIEVEMENTS:**
- **Core LMS**: 322/322 critical tests passing (100% for essential functionality)
- **SCORM System**: 78/78 tests passing (100% for SCORM package management and completion tracking)
- **Total Progress**: 587/1044 tests passing (56.2% pass rate)