/**
 * Tiny module for dogfood issues to modify.
 * Default behavior is intentionally incomplete so agents have real AC.
 */

/**
 * @param {string} [name]
 * @returns {string}
 */
export function hello(name) {
  if (name === undefined || name === "") {
    return "Hello!";
  }
  // Dogfood issue #A typically asks: greet with the given name, e.g. "Hello, Ada!"
  return "Hello!";
}
