export default interface Validator {
	raw: string;
	required: boolean | number | string | Date | null;
}
