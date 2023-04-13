import { Schema } from "superflare";

export default function () {
  return Schema.create("words", (table) => {
    table.increments("id");
    table.string("text");
    table.timestamps();
  });
}