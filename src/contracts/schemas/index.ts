import memoize from "memoize";
import {
  any,
  array,
  bigint,
  Failure,
  Infer,
  integer,
  min,
  number,
  object,
  pattern,
  refine,
  string,
  union,
  validate,
} from "superstruct";

export const IntegerSchema = memoize(() =>
  object({
    int: union([
      min(integer(), 0),
      refine(bigint(), "positive_bigint", (value) => value >= 0n),
    ]),
  })
);
export type IntegerSchemaStructType = ReturnType<typeof IntegerSchema>;
export type IntegerSchemaType = Infer<IntegerSchemaStructType>;
export const expectInteger = (value: unknown, message?: string) => {
  const res = validate(value, IntegerSchema());
  if (res[0]) {
    throw new Error(message ?? res[0].message);
  }
  return res[1];
};

export const ByteStringSchema = memoize(() =>
  object({
    bytes: pattern(string(), /^([0-9a-fA-F]{2})*$/),
  })
);
export type ByteStringSchemaStructType = ReturnType<typeof ByteStringSchema>;
export type ByteStringSchemaType = Infer<ByteStringSchemaStructType>;
export const expectByteString = (value: unknown, message?: string) => {
  const res = validate(value, ByteStringSchema());
  if (res[0]) {
    throw new Error(message ?? res[0].message);
  }
  return res[1];
};

export const ListSchema = memoize(() =>
  object({
    list: array(any()),
  })
);
export type ListSchemaStructType = ReturnType<typeof ListSchema>;
export type ListSchemaType = Infer<ListSchemaStructType>;
export const expectList = (value: unknown, message?: string) => {
  const res = validate(value, ListSchema());
  if (res[0]) {
    throw new Error(message ?? res[0].message);
  }
  return res[1];
};

// ConStr
export const ConStrSchema = memoize((index: number, length: number) =>
  refine(
    object({
      constructor: refine(
        union([bigint(), number()]),
        "constructor",
        (value) => {
          if (Number(value) === index) {
            return true;
          }
          return {
            message: `constructor must be ${index}`,
            path: ["constructor"],
          };
        }
      ),
      fields: array(any()),
    }),
    "constr_obj",
    ({ fields }) => {
      // check length
      if (fields.length !== length) {
        const failure: Partial<Failure> = {
          message: `has ${fields.length} items, but expected ${length}`,
          path: ["fields"],
        };
        return failure;
      }
      return true;
    }
  )
);
export type ConStrSchemaStructType = ReturnType<typeof ConStrSchema>;
export const expectConStr = (
  value: unknown,
  index: number,
  length: number,
  message?: string
) => {
  const res = validate(value, ConStrSchema(index, length));
  if (res[0]) {
    throw new Error(message ?? res[0].message);
  }
  return res[1];
};

export type PlutusDataSchemaStructType =
  | IntegerSchemaStructType
  | ByteStringSchemaStructType
  | ListSchemaStructType
  | ConStrSchemaStructType;
export type PlutusDataSchemaType = Infer<PlutusDataSchemaStructType>;
