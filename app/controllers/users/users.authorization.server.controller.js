"use strict";

/**
 * Module dependencies.
 */
var _ = require("lodash"),
  User = require("../../models/user.server.model");

/**
 * User middleware
 */
exports.userByID = function(req, res, next, id) {
  User.findById(id).exec(function(err, user) {
    if (err) return next(err);
    if (!user) return next(new Error("Failed to load User " + id));
    req.profile = user;
    next();
  });
};

/**
 * Require login routing middleware
 */
exports.requiresLogin = function(req, res, next) {
  if (process.env.NODE_ENV === "development") {
    return next();
  }

  if (!req.isAuthenticated()) {
    return res.status(401).send({
      message: "User is not logged in",
    });
  }

  next();
};

exports.requiresTest = function(req, res, next) {
  console.log("this matches");
  next();
};

/**
 * User authorizations routing middleware
 */
exports.hasAuthorization = function(roles) {
  var _this = this;

  return function(req, res, next) {
    _this.requiresLogin(req, res, function() {
      if (_.intersection(req.user.roles, roles).length) {
        return next();
      } else {
        return res.status(403).send({
          message: "User is not authorized",
        });
      }
    });
  };
};
