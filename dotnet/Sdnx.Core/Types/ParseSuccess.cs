namespace Sdnx.Core
{
    public class ParseSuccess<T>
    {
        public bool Ok => true;
        public T Data { get; set; }

        public ParseSuccess()
        {
            Data = default!;
        }

        public ParseSuccess(T data)
        {
            Data = data;
        }
    }
}
