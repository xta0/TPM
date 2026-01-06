/*
 * Copyright (c) Vizlab Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation

extension SDKCentralCache {
  enum Keys: String, CaseIterable {
    // MARK: - The setting cache keys

    case advertisingTrackingStatus = "com.ahsdk.settings.AHSDKSettingsAdvertisingTrackingStatus"
    case bitmask = "com.ahsdk.settings.AHSDKSettingsBitmask"
    case dataProcessingOptions = "com.ahsdk.settings.AHSDKSettingsDataProcessingOptions"
    case dataSourceID = "com.ahsdk.GatewayDataSourceID"
    case domain = "com.ahsdk.GatewayDomain"
    case internalUserData = "com.ahsdk.settings.appevents.UserDataStore.internalUserData"
    case isAdvertiserIDCollectionEnabled = "com.ahsdk.settings.AdvertiserIDCollectionEnabled"
    case isAutoLogAppEventsEnabled = "com.ahsdk.settings.AutoLogAppEventsEnabled"
    case isServerAdvertiserIDCollectionEnabled = "com.ahsdk.settings.ServerAdvertiserIDCollectionEnabled"
    case limitEventAndDataUsage = "com.ahsdk.settings.AHSDKSettingsLimitEventAndDataUsage"
    case userData = "com.ahsdk.settings.appevents.UserDataStore.userData"

    // MARK: - The other cache keys

    case AppEventCacheKey = "com.ahsdk.default.AppEventsConfigurationKey"
    case AppEventConfigNextFetchTime = "com.ahsdk.default.AppEventsConfigurationFetchTime"
    case AppLifeCycleLastSuspendDate = "com.ahsdk.default.lastSuspendDate"
    case AppLinkParamsKey = "com.ahsdk.default.AppEventsUtility.appLinkParams"
    case EndpointBackoffTimePrefix = "com.ahsdk.default.backoffTime"
    case EndpointBackoffRetryCount = "com.ahsdk.default.backoffRetryCount"
    case FeatureManagerFeaturePrefix = "com.ahsdk.default.AHSDKFeatureManager.Feature"
    case GenATEOperatorLastATEPing = "com.ahsdk.default.lastATEPing"
    case GenInstallOperatorAppInstallTimestamp = "com.ahsdk.default.appInstallTimestamp"
    case GenInstallOperatorIsSKANInstallReported = "com.ahsdk.default.IsSkAdNetworkInstallReported"
    case GenInstallOperatorLastAttributionPing = "com.ahsdk.default.lastAttributionPing"
    case InAppPurchaseOriginalTransactionSetKey = "com.ahsdk.default.InAppPurchase.originalTransaction"
    case RelatedMinidumpNamesAndSDKVersion = "com.ahsdk.default.RelatedMinidumpNamesAndSDKVersion"
    case SKANReporterKey = "com.ahsdk.default.AHSDKSKAdNetworkReporter"
    case UnSentCrashReports = "com.ahsdk.default.UnSentCrashReports"
    case CachedSDKVersion = "com.ahsdk.default.CachedSDKVersion"
    case DisabledFeaturesWTimeStamps = "com.ahsdk.default.DisabledFeaturesWTimeStamps"
    case TraceID = "com.ahsdk.default.TraceID"
    case HasMigratedPIIFromFBSDK = "com.ahsdk.default.HasMigratedPIIFromFBSDK"
    // delete this key after 1.1.0
    case cacheHasBeenMigrated = "com.ahsdk.default.CacheHasBeenMigrated"

    // MARK: - The IAP cache keys

    case SKV2NewCandidateDate = "com.ahsdk.iap.SKV2NewCandidateDate"
    case SKV2RestoredTransactionCheckDate = "com.ahsdk.iap.SKV2RestoredTransactionCheckDate" // The date when check the restored event, reserved for potential future use
  }
}
