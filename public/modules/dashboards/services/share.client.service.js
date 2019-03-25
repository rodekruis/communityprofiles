"use strict";

// Share URL
// Service to generate a url to share the current view/state of the dashboard
//
angular.module("dashboards").factory("shareService", [
  function() {
    /**
     * Create parameter-specific URL
     *
     * @returns {String}
     *  */
    function createFullUrl(
      country,
      admlevel,
      metric,
      parent_code,
      disaster,
      event,
      viewType
    ) {
      var currentUrl = location.href;
      var baseUrl = currentUrl.split("?")[0];
      var separator = currentUrl.indexOf("?") !== -1 ? "&" : "?";
      var urlParameters = "country=" + country;

      if (admlevel) {
        urlParameters += "&admlevel=" + admlevel;
      }

      if (metric) {
        urlParameters += "&metric=" + metric;
      }

      if (parent_code) {
        urlParameters += "&parent_code=" + parent_code;
      }

      if (disaster) {
        urlParameters += "&disaster=" + disaster;
      }

      if (event) {
        urlParameters += "&event=" + event;
      }

      if (viewType) {
        urlParameters += "&view=" + viewType;
      }

      return baseUrl + separator + urlParameters;
    }

    /**
     * @param {String} countryCode
     *
     * @returns {String}
     */
    function createCountryUrl(countryCode) {
      return location.href + "?country=" + countryCode;
    }

    function copyToClipboard(text) {
      var tempInput = document.createElement("input");

      document.body.append(tempInput);
      tempInput.value = text;
      tempInput.select();
      document.execCommand("copy");
      tempInput.parentNode.removeChild(tempInput);
    }

    return {
      createFullUrl: createFullUrl,
      createCountryUrl: createCountryUrl,
      copyToClipboard: copyToClipboard,
    };
  },
]);
