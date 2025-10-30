# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
## [1.1.0] - 2023-10-31

### Changed
- Update module to support v9.x of upstream provider.  This migrated target groups and listeners to use maps instead of lists.  This prevents original behaviour of recreating resources when adding/removing configuration from anywhere besides the end of a list.
- Tests now use `terraform` config repo shared terragrunt.hcl.  This should move to us-east-2 eventually.

## [1.0.1] - 2023-10-23
### Fixed
- Issue with `var.target_groups`. `targets` mapping previously required all child objects, preventing association of a target group without having a standalone EC2 instance also associated.

## [1.0.0] - 2023-10-19
### Added
- Initial release.

[Unreleased]: https://gitlab.versatilecredit.com/vci/devops/terraform/aws-lb/-/compare/v1.1.0...main
[1.1.0]: https://gitlab.versatilecredit.com/vci/devops/terraform/aws-lb/-/compare/v1.0.1...v1.1.0
[1.0.1]: https://gitlab.versatilecredit.com/vci/devops/terraform/aws-lb/-/compare/v1.0.0...v1.0.1
[1.0.0]: https://gitlab.versatilecredit.com/vci/devops/terraform/aws-lb/-/commits/v1.0.0
