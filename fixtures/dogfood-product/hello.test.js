import { test } from "node:test";
import assert from "node:assert/strict";
import { hello } from "./hello.js";

test("hello with no name", () => {
  assert.equal(hello(), "Hello!");
  assert.equal(hello(""), "Hello!");
});

// Intentionally absent until dogfood issue #A (or host tick) implements it:
// test("hello with name", () => {
//   assert.equal(hello("Ada"), "Hello, Ada!");
// });
