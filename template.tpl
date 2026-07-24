___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "displayName": "ConsentKit CMP",
  "description": "Deploys the ConsentKit consent widget and connects it to Google Consent Mode v2: default consent states with optional region targeting, returning-visitor consent restore, and consent updates driven by the widget. ConsentKit is a US-privacy-focused consent management platform - https://consentkit.us",
  "categories": [
    "TAG_MANAGEMENT",
    "UTILITY"
  ],
  "securityGroups": [],
  "id": "cvt_temp_public_id",
  "type": "TAG",
  "version": 1,
  "brand": {
    "id": "github.com_ruca-radio",
    "displayName": "ConsentKit"
  },
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "siteId",
    "displayName": "ConsentKit Site ID",
    "simpleValueType": true,
    "valueHint": "e.g. my-site-a1b2c3d4",
    "help": "The site ID from your ConsentKit dashboard (Sites \u003e your site \u003e Installation). It becomes the widget's data-site-id attribute.",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "apiUrl",
    "displayName": "API URL (optional)",
    "simpleValueType": true,
    "defaultValue": "https://api.consentkit.us",
    "valueHint": "https://api.consentkit.us",
    "help": "Only change this if you self-host the ConsentKit API. Becomes the widget's data-api attribute."
  },
  {
    "type": "CHECKBOX",
    "name": "debug",
    "checkboxText": "Enable widget debug logging",
    "simpleValueType": true,
    "help": "Adds the widget's data-debug attribute, which makes the widget log to the browser console."
  },
  {
    "type": "GROUP",
    "name": "consentDefaults",
    "displayName": "Default consent state (Google Consent Mode)",
    "groupStyle": "NO_ZIPPY",
    "subParams": [
      {
        "type": "SELECT",
        "name": "defaultAnalyticsStorage",
        "displayName": "analytics_storage",
        "macrosInSelect": false,
        "selectItems": [
          {
            "value": "denied",
            "displayValue": "denied"
          },
          {
            "value": "granted",
            "displayValue": "granted"
          }
        ],
        "simpleValueType": true,
        "defaultValue": "denied"
      },
      {
        "type": "SELECT",
        "name": "defaultAdStorage",
        "displayName": "ad_storage",
        "macrosInSelect": false,
        "selectItems": [
          {
            "value": "denied",
            "displayValue": "denied"
          },
          {
            "value": "granted",
            "displayValue": "granted"
          }
        ],
        "simpleValueType": true,
        "defaultValue": "denied"
      },
      {
        "type": "SELECT",
        "name": "defaultAdUserData",
        "displayName": "ad_user_data",
        "macrosInSelect": false,
        "selectItems": [
          {
            "value": "denied",
            "displayValue": "denied"
          },
          {
            "value": "granted",
            "displayValue": "granted"
          }
        ],
        "simpleValueType": true,
        "defaultValue": "denied"
      },
      {
        "type": "SELECT",
        "name": "defaultAdPersonalization",
        "displayName": "ad_personalization",
        "macrosInSelect": false,
        "selectItems": [
          {
            "value": "denied",
            "displayValue": "denied"
          },
          {
            "value": "granted",
            "displayValue": "granted"
          }
        ],
        "simpleValueType": true,
        "defaultValue": "denied"
      },
      {
        "type": "TEXT",
        "name": "defaultRegion",
        "displayName": "Region (optional)",
        "simpleValueType": true,
        "valueHint": "US-CA, US-CT",
        "help": "Comma-separated ISO 3166-2 region codes these defaults apply to (e.g. US-CA, US-CT). Leave blank to apply the defaults to all regions."
      },
      {
        "type": "TEXT",
        "name": "waitForUpdate",
        "displayName": "Wait for update (ms)",
        "simpleValueType": true,
        "defaultValue": "500",
        "valueHint": "500",
        "help": "How long consent-gated tags wait for the first consent update before firing. Matches the ConsentKit widget's own default of 500 ms. Set to 0 to disable."
      }
    ]
  },
  {
    "type": "GROUP",
    "name": "advanced",
    "displayName": "Advanced",
    "groupStyle": "ZIPPY_CLOSED",
    "subParams": [
      {
        "type": "TEXT",
        "name": "loaderUrl",
        "displayName": "Widget loader URL",
        "simpleValueType": true,
        "defaultValue": "https://widget.consentkit.us/gtm/loader.js",
        "valueHint": "https://widget.consentkit.us/gtm/loader.js",
        "help": "GTM cannot set data-* attributes on injected scripts, so the template loads this tiny bridge which creates the widget script tag with the required attributes. It is served by the ConsentKit widget worker. Only change this if you self-host the ConsentKit widget worker; if you do, add a matching pattern under Permissions \u003e Injects Scripts."
      }
    ]
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

// ConsentKit CMP — Google Tag Manager custom tag template.
//
// What this template does, in order:
//   1. Sets the Google Consent Mode default consent state from the tag
//      fields (BEFORE any consent-gated tags fire). This tag must be
//      triggered on Consent Initialization.
//   2. Restores a returning visitor's saved consent from the widget's
//      `consentkit_prefs` cookie so consent-gated tags behave correctly
//      from the very first event.
//   3. Loads the ConsentKit widget. GTM's injectScript API cannot set
//      data-* attributes on the script tag it creates, and the ConsentKit
//      widget reads its configuration (data-site-id, data-api, data-debug)
//      from its own script tag. The template therefore passes the
//      configuration through window.ConsentKit_GTM and injects a tiny
//      loader script which creates the real widget script tag with the
//      required attributes. The loader is served by the ConsentKit widget
//      worker itself at https://widget.consentkit.us/gtm/loader.js
//      (source: gtm-template/loader.js in the consentkit repo).
//   4. When the widget reports a consent choice it pushes
//      {event: 'consent_update', consent_preferences: {...}} to the
//      dataLayer. Attach a Custom Event trigger for `consent_update` to
//      this same tag: the template then calls updateConsentState so GTM's
//      consent state follows the visitor's choice.

const setDefaultConsentState = require('setDefaultConsentState');
const updateConsentState = require('updateConsentState');
const copyFromDataLayer = require('copyFromDataLayer');
const getCookieValues = require('getCookieValues');
const setInWindow = require('setInWindow');
const injectScript = require('injectScript');
const queryPermission = require('queryPermission');
const logToConsole = require('logToConsole');
const getType = require('getType');
const makeInteger = require('makeInteger');
const JSON = require('JSON');

const DEFAULT_LOADER_URL =
  'https://widget.consentkit.us/gtm/loader.js';

// Map a ConsentKit preferences object ({necessary, analytics, marketing})
// to Google Consent Mode consent types. This mirrors the widget's own
// gtag mapping in widget/v1.js (updateGTMConsent).
const toConsentState = function(prefs) {
  const marketing = prefs.marketing === true ? 'granted' : 'denied';
  return {
    'analytics_storage': prefs.analytics === true ? 'granted' : 'denied',
    'ad_storage': marketing,
    'ad_user_data': marketing,
    'ad_personalization': marketing
  };
};

// ---------------------------------------------------------------------------
// Consent update path: the widget pushed a consent_update event.
// ---------------------------------------------------------------------------
if (copyFromDataLayer('event') === 'consent_update') {
  const prefs = copyFromDataLayer('consent_preferences');

  if (prefs && getType(prefs) === 'object') {
    updateConsentState(toConsentState(prefs));
    logToConsole('ConsentKit: consent update applied', prefs);
  } else {
    logToConsole('ConsentKit: consent_update event without preferences');
  }

  data.gtmOnSuccess();

// ---------------------------------------------------------------------------
// Initialization path: defaults, returning-visitor restore, widget load.
// ---------------------------------------------------------------------------
} else {

  // 1. Default consent state (before the widget loads). The four ads /
  //    analytics types come from the tag fields; functionality and security
  //    storage mirror the widget's own gtag defaults (widget/v1.js
  //    setDefaultGTMConsent): functionality and security are always granted,
  //    personalization_storage is denied until marketing consent.
  const defaultConsent = {
    'analytics_storage': data.defaultAnalyticsStorage || 'denied',
    'ad_storage': data.defaultAdStorage || 'denied',
    'ad_user_data': data.defaultAdUserData || 'denied',
    'ad_personalization': data.defaultAdPersonalization || 'denied',
    'functionality_storage': 'granted',
    'personalization_storage': 'denied',
    'security_storage': 'granted'
  };

  // Optional region restriction: comma-separated ISO 3166-2 codes
  // (e.g. "US-CA, US-CT"). Empty means the defaults apply worldwide.
  const regionStr = data.defaultRegion || '';
  const regions = regionStr.split(',')
    .map(function(region) { return region.trim(); })
    .filter(function(region) { return region.length !== 0; });
  if (regions.length > 0) {
    defaultConsent.region = regions;
  }

  const waitForUpdate = makeInteger(data.waitForUpdate);
  if (waitForUpdate > 0) {
    defaultConsent.wait_for_update = waitForUpdate;
  }

  setDefaultConsentState(defaultConsent);
  logToConsole('ConsentKit: default consent state set', defaultConsent);

  // 2. Returning visitor fast-path: if the widget's consent cookie exists,
  //    apply the saved choices immediately so consent-gated tags are
  //    unblocked from the first event instead of waiting for the widget to
  //    load and re-broadcast. The widget also pushes consent_update for
  //    returning visitors, which the update path above applies again.
  const cookieValues = getCookieValues('consentkit_prefs');
  if (cookieValues && cookieValues.length > 0) {
    const savedPrefs = JSON.parse(cookieValues[0]);
    if (savedPrefs && getType(savedPrefs) === 'object') {
      updateConsentState(toConsentState(savedPrefs));
      logToConsole('ConsentKit: restored consent from cookie', savedPrefs);
    }
  }

  // 3. Load the widget. The site ID is required; without it there is
  //    nothing sensible to do, so fail the tag.
  const siteId = data.siteId;
  if (!siteId) {
    logToConsole('ConsentKit: Site ID is missing');
    data.gtmOnFailure();
  } else {
    // Hand the configuration to the loader through a window global; the
    // loader creates the widget script tag with the data-* attributes the
    // widget reads (data-site-id, data-api, data-debug).
    setInWindow('ConsentKit_GTM', {
      siteId: siteId,
      apiUrl: data.apiUrl || 'https://api.consentkit.us',
      debug: data.debug === true
    }, true);

    const loaderUrl = data.loaderUrl || DEFAULT_LOADER_URL;

    if (queryPermission('inject_script', loaderUrl)) {
      // The cache token dedupes the injection if the tag fires more than
      // once on the same page.
      injectScript(loaderUrl, data.gtmOnSuccess, data.gtmOnFailure,
        'consentkit-gtm-loader');
    } else {
      logToConsole('ConsentKit: inject_script not permitted for', loaderUrl);
      data.gtmOnFailure();
    }
  }
}


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "inject_script",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://widget.consentkit.us/*"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_consent",
        "versionId": "1"
      },
      "param": [
        {
          "key": "consentTypes",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "ad_storage"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "ad_user_data"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "ad_personalization"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "analytics_storage"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "functionality_storage"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "personalization_storage"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "security_storage"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "wait_for_update"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_data_layer",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedKeys",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "keyPatterns",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "event"
              },
              {
                "type": 1,
                "string": "consent_preferences"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "cookieAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "cookieNames",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "consentkit_prefs"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_globals",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "ConsentKit_GTM"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: Init sets default consent and injects the widget loader
  code: |-
    mockData.siteId = 'my-site-a1b2c3d4';
    mockData.waitForUpdate = '500';

    runCode(mockData);

    assertApi('setDefaultConsentState').wasCalledWith({
      'analytics_storage': 'denied',
      'ad_storage': 'denied',
      'ad_user_data': 'denied',
      'ad_personalization': 'denied',
      'functionality_storage': 'granted',
      'personalization_storage': 'denied',
      'security_storage': 'granted',
      'wait_for_update': 500
    });
    assertApi('setInWindow').wasCalledWith('ConsentKit_GTM', {
      siteId: 'my-site-a1b2c3d4',
      apiUrl: 'https://api.consentkit.us',
      debug: false
    }, true);
    assertApi('injectScript').wasCalled();
    assertApi('updateConsentState').wasNotCalled();
- name: consent_update event updates consent state
  code: |-
    mock('copyFromDataLayer', (key) => {
      if (key === 'event') return 'consent_update';
      if (key === 'consent_preferences') {
        return { necessary: true, analytics: true, marketing: false };
      }
    });

    runCode(mockData);

    assertApi('updateConsentState').wasCalledWith({
      'analytics_storage': 'granted',
      'ad_storage': 'denied',
      'ad_user_data': 'denied',
      'ad_personalization': 'denied'
    });
    assertApi('setDefaultConsentState').wasNotCalled();
    assertApi('injectScript').wasNotCalled();
- name: Returning visitor consent is restored from the widget cookie
  code: |-
    mockData.siteId = 'my-site-a1b2c3d4';
    mock('getCookieValues', (name) => {
      if (name === 'consentkit_prefs') {
        return ['{"necessary":true,"analytics":false,"marketing":true}'];
      }
      return [];
    });

    runCode(mockData);

    assertApi('updateConsentState').wasCalledWith({
      'analytics_storage': 'denied',
      'ad_storage': 'granted',
      'ad_user_data': 'granted',
      'ad_personalization': 'granted'
    });
    assertApi('setDefaultConsentState').wasCalled();
    assertApi('injectScript').wasCalled();


___NOTES___
ConsentKit CMP v1.0.0
* Initial version
