// Don't change signature of existing functions. You may write additional helper functions if you want.
// Description: 32-bit right barrel shifter
// Arguments: in (value to be shifted); sftSz (shift size); sft_in (the bit shifted in)
// Return: {sft_in's, in[31:sftSz]}
function Bit#(32) barrelRShift(Bit#(32) in, Bit#(5) sftSz, Bit#(1) sft_in);
    Bit#(32) ret = 0;
    //5 muxes
    if (sft_in == 0) begin
        Bit#(32) r4 = (sftSz[4] == 0) ? in : {16'b0000000000000000, in[31:16]};
        Bit#(32) r3 = (sftSz[3] == 0) ? r4 : {8'b00000000, r4[31:8]};
        Bit#(32) r2 = (sftSz[2] == 0) ? r3 : {4'b0000, r3[31:4]};
        Bit#(32) r1 = (sftSz[1] == 0) ? r2 : {2'b00, r2[31:2]};
        ret = (sftSz[0] == 0) ? r1 : {1'b0, r1[31:1]};
    end
    if (sft_in == 1) begin
        Bit#(32) r4 = (sftSz[4] == 0) ? in : {16'b1111111111111111, in[31:16]};
        Bit#(32) r3 = (sftSz[3] == 0) ? r4 : {8'b11111111, r4[31:8]};
        Bit#(32) r2 = (sftSz[2] == 0) ? r3 : {4'b1111, r3[31:4]};
        Bit#(32) r1 = (sftSz[1] == 0) ? r2 : {2'b11, r2[31:2]};
        ret = (sftSz[0] == 0) ? r1 : {1'b1, r1[31:1]};
        end
    //ret = r0;
    return ret;
endfunction

// Description: 32-bit arithmetic/logic right shifter
// Arguments: in (value to be shifted); sftSz (shift size); arith (1 = arithmetic, 0 = logic)
// Return: in >> sftSz
function Bit#(32) sr32(Bit#(32) in, Bit#(5) sftSz, Bit#(1) arith);
    Bit#(32) ret = 0;
    //////////////////
    // YOUR CODE HERE
    /////////////////
    Bit#(1) shv = in[31];
    if (arith == 0) begin
        shv = 0;
    end
    ret = barrelRShift(in, sftSz, shv);
    return ret;
endfunction


// Description: 32-bit logic left shifter
// Arguments: in (values to be shifted); sftSz (shift size)
// Return: a << b
function Bit#(32) sll32(Bit#(32) in, Bit#(5) sftSz);
    Bit#(32) ret = 0;
    //////////////////
    // YOUR CODE HERE
    /////////////////
    in = reverseBits(in);
    ret = barrelRShift(in, sftSz, 0);
    ret = reverseBits(ret);
    return ret;
endfunction


// Description: 32-bit FULL shifter
// Arguments: in (value to be shifted); sftSz (shift size);
// ShiftTypes:
// LogicalRightShift
// ArithmeticRightShift
// LeftShift
//
// Return: in >> sftSz when right shift; in << sftSz otherwise
typedef enum {LogicalRightShift, ArithmeticRightShift, LeftShift} ShiftType;

function Bit#(32) sft32(Bit#(32) in, Bit#(5) sftSz, ShiftType shiftType);
    Bit#(32) ret = 0;
    //////////////////
    // YOUR CODE HERE
    /////////////////
    Bit#(1) shv = 0;
    if (shiftType == ArithmeticRightShift)begin
        if (in[31] == 1)begin
            shv = 1;
        end
    end
    if (shiftType == LeftShift)begin
        in = reverseBits(in);
    end
    ret = barrelRShift(in, sftSz, shv);
    if (shiftType == LeftShift)begin
        ret = reverseBits(ret);
    end

    return ret;
endfunction



// Description: one-bit less-than comparator
// Arguments: a, b (1-bit values), eq, lt (eq and lt from previous comparator)
// Return: {eq_i, lt_i}
function Bit#(2) cmp(Bit#(1) a, Bit#(1) b, Bit#(1) eq, Bit#(1) lt);
    Bit#(2) ret = 0;
    //////////////////
    // YOUR CODE HERE
    /////////////////
    ret[1] = ((a&b) | (~a&~b)) & eq;

    ret[0] = (a&~b & lt) | ((b&~a) & eq) | (lt);
    //ret[1] = eq;
    //ret[0] = lt;
    return ret;
endfunction

// Description: unsigned 32-bit less-than comparator
// Arguments: a, b unsigned 32-bit values
// Return: 1 if a < b
function Bit#(1) ltu32(Bit#(32) a, Bit#(32) b);
    Bit#(1) ret = 0;
    //////////////////
    // YOUR CODE HERE
    /////////////////
    Bit#(1) eq = 1;
    Bit#(1) lt = 0;
    Bit#(2) result = 0;
    for (Integer i = 31; i>-1; i=i-1)begin
        result = cmp(a[i], b[i], eq, lt);
        eq = result[1];
        lt = result[0];
    end
    ret = lt;
    return ret;
endfunction

// Description: Signed/Unsigned 32-bit less-than comparator
// Arguments: a b (32-bit values); isSigned (signed comparator when 1, unsigned otherwise)
// Return: 1 if a < b
function Bit#(1) lt32(Bit#(32) a, Bit#(32) b, Bit#(1) isSigned);
    Bit#(1) ret = 0;
    //////////////////
    // YOUR CODE HERE
    /////////////////
    Bit#(1) lt = ltu32(a, b);
    if (isSigned == 1) begin
        if (a[31] != b[31])begin
            lt = a[31];
        end
    end
    ret = lt;
    return ret;
endfunction

// Description: one-bit full adder
// Arguments: a, b, carry in
// Return: {carry out, sum}
function Bit#(2) fullAdder(Bit#(1) a, Bit#(1) b, Bit#(1) carryIn);
    Bit#(2) ret = 0;
    Bit#(1) c = carryIn;
    ret[0] = (a&b&c) | (a&~b&~c) | (~a&b&~c) | (~a&~b&c);
    ret[1] = (a&b&c) | (a&b&~c) | (a&~b&c) | (~a&b&c);
    return ret;
endfunction

// Description: n-bit ripple-carry adder with a carry-in
// Arguments: a, b, carryIn
// Return: sum of a, b, and carryIn
function Bit#(n) rca#(Integer n)(Bit#(n) a, Bit#(n) b, Bit#(1) carryIn);
    Bit#(n) ret = 0;
    //////////////////
    // YOUR CODE HERE
    /////////////////
    Bit#(2) calc = 0;
    for (Integer i = 0; i < n; i=i+1)begin
        calc = fullAdder(a[i], b[i], carryIn);
        ret[i] = calc[0];
        carryIn = calc[1];
    end
    return ret;
endfunction

// Description: n-bit ripple-carry adder/subractor
// Arguments: a, b (n-bit operands); isSub (1 => subtract, 0 => add)
// Return: isSub == 0 ? a + b : a - b
function Bit#(n) addSub#(Integer n)(Bit#(n) a, Bit#(n) b, Bit#(1) isSub);
    Bit#(n) ret = 0;
    //////////////////
    // YOUR CODE HERE
    /////////////////
    Bit#(1) xorval = 1;
    Bit#(n) xorvalextend = signExtend(xorval);
    Bit#(1) initcarryin = 0;
    if (isSub == 1)begin
        b = b^xorvalextend;
        initcarryin = 1;
    end
    ret = fastAdd#(n)(a, b, initcarryin);
    return ret;
endfunction


// Alu Functions:
// Add: 32-bit Addition         (a + b)
// Sub: 32-bit Subtraction      (a - b)
// And: 32-bit Bitwise And      (a & b)
// Or: 32-bit Bitwise Or        (a | b)
// Xor: 32-bit Bitwise Xor      (a ^ b)
// Slt: Set less than           (a <u b ? 1 : 0)
// Sltu: Set less than unsigned (a <s b ? 1:0)
// Sll: Left logic shift        (a << b)
// Srl: Right logic shift       (a >>u b)
// Sra: Right arithmetic shift  (a >>s b)
typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc;

// Description: Arithmetic Logic Unit (ALU)
// Arguments: a, operand a; b, operand b; func, ALU operation
// Return: output of ALU
function Bit#(32) alu(Bit#(32) a, Bit#(32) b, AluFunc func);
    Bit #(32) ret = 0;
    //////////////////
    // YOUR CODE HERE
    /////////////////
    Bit#(1) useAddSub = 0;
    Bit#(1) isSub = 0;
    Bit#(1) uselt32 = 0;
    Bit#(1) ltreturn = 0;
    Bit#(1) isSigned = 0;
    Bit#(1) useSft32 = 0;
    ShiftType sfttype = ArithmeticRightShift;
    if (func == Add)begin
        useAddSub = 1;
    end
    if (func == Sub)begin
        useAddSub = 1;
        isSub = 1;
    end
    if (useAddSub == 1)begin
        ret = addSub#(32)(a, b, isSub);
    end
    if (func == Slt)begin
        uselt32 = 1;
        isSigned = 1;
    end
    if (func == Sltu)begin
        uselt32 = 1;
    end
    if (uselt32 == 1)begin
        ltreturn = lt32(a, b, isSigned);
        ret = zeroExtend(ltreturn);
    end
//typedef enum {LogicalRightShift, ArithmeticRightShift, LeftShift} ShiftType;
    if (func == Sll)begin
        useSft32 = 1;
        sfttype = LeftShift;
    end
    if (func == Srl)begin
        useSft32 = 1;
        sfttype = LogicalRightShift;
    end
    if (func == Sra)begin
        useSft32 = 1;
        sfttype = ArithmeticRightShift;
    end
    if (useSft32 == 1)begin
        ret = sft32(a, b[4:0], sfttype);
    end
    if (func == And)begin
        ret = a&b;
    end
    if (func == Or)begin
        ret = a | b;
    end
    if (func == Xor)begin
        ret = a ^ b;
    end


    return ret;
endfunction


// Description: Alternative shifter implementation (Discussion Question)
function Bit#(32) sft32_alt(Bit#(32) in, Bit#(5) sftSz, ShiftType shiftType);
    return (shiftType == LeftShift) ? sft32(in, sftSz, LeftShift) : ((shiftType == ArithmeticRightShift)? sft32(in, sftSz, ArithmeticRightShift) : sft32(in, sftSz, LogicalRightShift));
endfunction


// Description: N-bit fast adder with a carry-in (Design Exercise)
// Arguments: a, b, carryIn
// Return: sum of a, b, and carryIn
function Bit#(1) singleFastAdder(Bit#(1) a, Bit#(1) b, Bit#(1) carryIn);
    Bit#(1) ret = 0;
    Bit#(1) c = carryIn;
    ret = (a&b&c) | (a&~b&~c) | (~a&b&~c) | (~a&~b&c);
    
    return ret;
endfunction

function Bit#(n) fastAdd#(Integer n)(Bit#(n) a, Bit#(n) b, Bit#(1) carryIn);
    Bit#(n) ret = 0;
    Bit#(n) gen_vals = 0;
    Bit#(n) prop_vals = 0;
    Bit#(n) carrycomb = 0;
    Bit#(n) comp = 0;
    ret[0] = singleFastAdder(a[0], b[0], carryIn);
    for (Integer i = 0; i < n; i = i+1)begin
        prop_vals[i] = a[i] | b[i];
    end
    for (Integer i=0; i < n; i=i+1)begin
        gen_vals[i] = prop_vals[i]&a[i]&b[i];
    end
    Bit#(1) prevgen = 0;
    for (Integer i = 1; i < n; i = i * 2) begin
        for (Integer j=n-1; i<=j; j=j-1) begin
            prevgen = gen_vals[j-i];
            gen_vals[j] = prop_vals[j] & prevgen | gen_vals[j];
            //prop_vals[j] = prop_vals[j] & prop_vals[j-i];
        end
        for (Integer j=n-1; i<=j; j=j-1) begin
            prop_vals[j] = prop_vals[j] & prop_vals[j-i];
        end
    end
    for (Integer i=1; i<n; i=i+1)begin
        Integer prev = i-1;
        carrycomb[i] = (prop_vals[prev]&carryIn) | gen_vals[prev];
        comp[i] = a[i]^b[i];
    end
    for (Integer i=1; i<n; i=i+1)begin
        ret[i] = carrycomb[i] ^ comp[i];
    end
    return ret;
endfunction