// NOTE: Can't use a narrower assertion like `x is Record<string, unknown>`
// because then type narrowing with the `in` operator stops working.
// <https://www.reddit.com/r/typescript/comments/tq3m4f/the_difference_between_object_and_recordstring/>
/** @returns {x is object} */
function isObject(/** @type {unknown} */ x) {
  // eslint-disable-next-line eqeqeq
  return typeof x === 'object' && x !== null && !Array.isArray(x);
}

/**
 * @template {string} Name
 * @returns {error is { name: Name }}
 */
function checkErrorName(/** @type {unknown} */ error, /** @type {Name} */ expectedName) {
  return isObject(error) && 'name' in error && error.name === expectedName;
}

/**
 * @template {string} Code
 * @returns {error is { code: Code }}
 */
function checkErrorCode(/** @type {unknown} */ error, /** @type {Code} */ expectedCode) {
  return isObject(error) && 'code' in error && error.code === expectedCode;
}

module.exports = { isObject, checkErrorName, checkErrorCode };
