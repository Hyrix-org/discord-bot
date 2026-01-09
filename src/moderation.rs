use std::sync::Arc;

use rustrict::Type;

// pub fn check(input: String) {
//     let (_, analysis) = rustrict::Censor::from_str(input)
//         .with_censor_threshold(Type::INAPPROPRIATE | Type::SEXUAL | Type::PROFANE)
//         .censor_and_analyze();
//     let bad_kinds = Type::SEXUAL | Type::OFFENSIVE | Type::PROFANE;
//     let severity_threshold = Type::MODERATE_OR_HIGHER;
//
//     analysis.is()
// }
