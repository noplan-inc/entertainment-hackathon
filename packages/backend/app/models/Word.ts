import { Model } from 'superflare';

export class Word extends Model {
  toJSON(): WordRow {
    return super.toJSON();
  }
}
Model.register(Word);

export interface Word extends WordRow {};