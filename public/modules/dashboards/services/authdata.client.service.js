"use strict";

angular.module("dashboards").factory("AuthData", [
  "$resource",
  function($resource) {
    /**
     * @param {String} country
     * @param {String} type
     *
     * @returns {Array}
     */
    function getPoi(options, success) {
      return $resource("/authdata/poi").query(
        {
          country: options.country,
          type: options.type,
        },
        success
      );
    }

    function getFbfJsonData(options, success) {
      return $resource("/authdata/json").query(
        {
          country: options.country,
          type: options.type,
        },
        success
      );
    }

    function getTable(options, success) {
      return $resource("/authdata/table").query(
        {
          schema: options.schema,
          table: options.table,
        },
        success
      );
    }

    return {
      getPoi: getPoi,
      getFbfJsonData: getFbfJsonData,
      getTable: getTable,
    };
  },
]);
