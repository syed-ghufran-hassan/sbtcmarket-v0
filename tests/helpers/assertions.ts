import { expect } from "vitest";

export function unwrapOk<T = any>(response: any): T {
  expect(response).toBeDefined();
  expect(response.type).toBe("ok");
  return response.value as T;
}

export function unwrapErr<T = any>(response: any): T {
  expect(response).toBeDefined();
  expect(response.type).toBe("err");
  return response.value as T;
}

export function expectUint(value: any, expected?: bigint | number) {
  expect(value).toBeDefined();
  expect(value.type).toBe("uint");
  const actual = BigInt(value.value);
  if (expected !== undefined) {
    expect(actual).toBe(BigInt(expected));
  }
  return actual;
}

export function expectBool(value: any, expected?: boolean) {
  expect(value).toBeDefined();
  if (value.type === "bool") {
    const actual = value.value as boolean;
    if (expected !== undefined) {
      expect(actual).toBe(expected);
    }
    return actual;
  }

  const actual = value.type === "true";
  if (expected !== undefined) {
    expect(actual).toBe(expected);
  }
  return actual;
}

export function unwrapOkUint(response: any, expected?: bigint | number) {
  const value = unwrapOk(response);
  return expectUint(value, expected);
}

export function unwrapErrUint(response: any, expected?: bigint | number) {
  const value = unwrapErr(response);
  return expectUint(value, expected);
}

