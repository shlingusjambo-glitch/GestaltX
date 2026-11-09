// SPDX-License-Identifier: GPL-3.0-only
#import <Foundation/Foundation.h>

// Only available local answers are returned. No identifiers are logged.
FOUNDATION_EXPORT NSDictionary<NSString *, id> * _Nonnull GXCopyCurrentDeviceIdentity(void);

// Read-only, explicitly allowlisted capabilities. Never returns device-unique IDs.
FOUNDATION_EXPORT NSDictionary<NSString *, id> * _Nonnull GXCopySiriCapabilityDiagnostics(void);
