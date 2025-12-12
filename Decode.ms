import ProcTypes;

////////////////////////////////////////////////////////////////////////////////////////////
/// The following are relevant types and constants for the decoder, copied from ProcTypes.ms
////////////////////////////////////////////////////////////////////////////////////////////
// typedef enum {OP, OPIMM, BRANCH, LUI, JAL, JALR, LOAD, STORE, AUIPC, Unsupported} IType;
// // Branch function enumeration
// typedef enum {Eq, Neq, Lt, Ltu, Ge, Geu} BrFunc;
// // Load/Store function enumeration
// typedef enum { Lw, Lh, Lhu, Lb, Lbu, Sw, Sh, Sb } MemFunc;

// typedef struct {
//     IType iType;
//     AluFunc aluFunc;
//     BrFunc brFunc;
//     MemFunc memFunc;
//     Maybe#(RIndx) dst;
//     RIndx src1;
//     RIndx src2;
//     Word imm;
// } DecodedInst;

// // Opcode
// Bit#(7) opOpImm  = 7'b0010011;
// Bit#(7) opOp     = 7'b0110011;
// Bit#(7) opLui    = 7'b0110111;
// Bit#(7) opJal    = 7'b1101111;
// Bit#(7) opJalr   = 7'b1100111;
// Bit#(7) opBranch = 7'b1100011;
// Bit#(7) opLoad   = 7'b0000011;
// Bit#(7) opStore  = 7'b0100011;
// Bit#(7) opAuipc  = 7'b0010111;
// // funct3 - ALU
// Bit#(3) fnADD   = 3'b000;
// Bit#(3) fnSLL   = 3'b001;
// Bit#(3) fnSLT   = 3'b010;
// Bit#(3) fnSLTU  = 3'b011;
// Bit#(3) fnXOR   = 3'b100;
// Bit#(3) fnSR    = 3'b101;
// Bit#(3) fnOR    = 3'b110;
// Bit#(3) fnAND   = 3'b111;
// // funct3 - Branch
// Bit#(3) fnBEQ   = 3'b000;
// Bit#(3) fnBNE   = 3'b001;
// Bit#(3) fnBLT   = 3'b100;
// Bit#(3) fnBGE   = 3'b101;
// Bit#(3) fnBLTU  = 3'b110;
// Bit#(3) fnBGEU  = 3'b111;
// // funct3 - Load
// Bit#(3) fnLW    = 3'b010;
// Bit#(3) fnLB    = 3'b000;
// Bit#(3) fnLH    = 3'b001;
// Bit#(3) fnLBU   = 3'b100;
// Bit#(3) fnLHU   = 3'b101;
// // funct3 - Store
// Bit#(3) fnSW    = 3'b010;
// Bit#(3) fnSB    = 3'b000;
// Bit#(3) fnSH    = 3'b001;
// // funct3 - JALR
// Bit#(3) fnJALR  = 3'b000;

function DecodedInst decode(Bit#(32) inst);
    let opcode = inst[6:0];
    let funct3 = inst[14:12];
    let funct7 = inst[31:25];
    let dst    = inst[11:7];
    let src1   = inst[19:15];
    let src2   = inst[24:20];

    Maybe#(RIndx) validDst = Valid(dst);
    Maybe#(RIndx) dDst = Invalid; // default value
    RIndx dSrc = 5'b0;
    // DEFAULT VALUES - Use the following for your default values:
    // dst: dDst
    // src1: dSrc
    // src2: dSrc
    // imm: immD32
    // brFunc: ?
    // aluFunc: ?
    // memFunc : ?
    // Since many groups of instructions use the same immediate constructed
    // from the same pattern of bits of the instruction (corresponding to the
    // "type", i.e. I-type, S-type, B-type, U-type, or J-type, described in the
    // RISC-V reference), we construct all the immediates first so we can use
    // them in multiple places. We can do this in two steps for each pattern:
    // (1) Concatenate all the immediate bits from the instruction.
    // (2) Sign-extend and/or pad with 0s on the right to produce a 32-bit word.
    // We have provided a default value and done immB for you.
    Word immD32 = signExtend(1'b0); // default value

    Bit#(12) immB = { inst[31], inst[7], inst[30:25], inst[11:8] };
    Word immB32 = signExtend({ immB, 1'b0 });
    // TODO: Consult the RISC-V reference and fill in the correct value for the
    // other immediates (these are provided in the order the microtests test
    // them):
    Bit#(20) immU = { inst[31:12] }; // TODO Replace 0 with the correct value
    Word immU32 = signExtend({immU, 12'b0});   // TODO Replace 0 with the correct value

    Bit#(12) immI = { inst[31:20] }; // TODO Replace 0 with the correct value
    Word immI32 = signExtend(immI);   // TODO Replace 0 with the correct value

    Bit#(20) immJ = { inst[31], inst[19:12], inst[20], inst[30:21]}; // TODO Replace 0 with the correct value
    Word immJ32 =  signExtend({ immJ, 1'b0 });   // TODO Replace 0 with the correct value
    
    Bit#(12) immS = { inst[31:25], inst[11:7] }; // TODO Replace 0 with the correct value
    Word immS32 = signExtend({ immS });   // TODO Replace 0 with the correct value
    DecodedInst dInst = unpack(0);
    dInst.iType = Unsupported; // unsupported by default
    case (opcode)
        // We have decoded AUIPC and some OP instructions for you.
        // TODO: Decode the remaining instruction types.
        opAuipc: begin
            // There are two ways you might want to construct the DecodedInst.
            // One is to create a complete DecodedInst all at once, which you
            // can do with this syntax: the name of the struct "DecodedInst"
            // followed by curly braces. Inside the braces, each field is
            // specified by fieldName: fieldValue, separated by commas.
            // NOTE: this will only work after you've correctly filled in immU/immU32
            // above!
            dInst = DecodedInst {iType: AUIPC, dst: validDst, src1: dSrc, src2: dSrc, imm: immU32, brFunc: ?, aluFunc: ?, memFunc : ?};
        end
        opLui: begin
            // LUI is a simple instruction and is tested by microtest 1. You
            // can construct a DecodedInst as in the code above. (Make sure
            // you've also filled in immU/immU32.)
            // TODO: Decode instructions of type LUI here
            // After you've implemented decoding and executing LUI
            // instructions, your processor should pass microtest 1.
            dInst = DecodedInst {iType: LUI, dst: validDst, src1: dSrc, src2: dSrc, imm: immU32, brFunc: ?, aluFunc: ?, memFunc : ?};
        end

        opOpImm: begin
            // The other way to construct a DecodedInst is to assign to fields
            // of the struct individually, with dInst.fieldName = fieldValue.

            // In this block of code, we handle all OPIMM instructions, namely
            // ANDI, ORI, XORI, ADDI, SLTI, SLTUI, SLLI, SRLI, and SRAI. Since
            // all these instructions have the same iType, src1, and dst, we
            // can assign them here:
            dInst.iType = OPIMM;
            dInst.src1  = src1;
            dInst.imm   = immI32;
            dInst.dst   = validDst;

            // However, note that even if opcode == opOpImm, it's still
            // possible that the instruction we're decoding is invalid, for
            // example if funct3 (i.e. inst[14:12]) corresponds to SLLI, but
            // funct7 (i.e. inst[31:25]) is not all 0s. (If you consult the
            // RISC-V reference you'll see that valid SLLI instructions must
            // start with seven 0 bits.) In those cases we have to say that the
            // instruction is invalid by setting dInst.iType back to
            // Unsupported.
            // We also put the statement "dInst.iType = Unsupported;" in some
            // other places as placeholders, so that you can compile your
            // processor directly without having finished all the parts; they
            // are meant to be replaced.
            case (funct3)
                
                fnSLT : dInst.aluFunc = Slt;
                fnSLTU: dInst.aluFunc = Sltu; 
                fnAND : dInst.aluFunc = And; 
                fnOR  : dInst.aluFunc = Or;
                fnXOR : dInst.aluFunc = Xor;  
                fnADD : dInst.aluFunc = Add;// TODO: Replace this statement to decode the aluFunc for SLTUI instructions
                fnSLL : case (funct7)
                    7'b0000000: dInst.aluFunc = Sll;

                    default:    dInst.iType = Unsupported;
                endcase
                fnSR  : case (funct7)
                    7'b0000000: dInst.aluFunc = Srl; 
                    7'b0100000: dInst.aluFunc = Sra;
                    default:    dInst.iType = Unsupported;
                endcase
        default: dInst.iType = Unsupported;
    endcase


            // After you've implemented decoding and executing OPIMM
            // instructions, your processor should pass microtest 2.
        end
        opOp: begin
            dInst.iType = OP;
            dInst.src2 = src2;
            dInst.src1 = src1;
            
            dInst.dst = validDst;
            // TODO: Decode instructions of type OP here (i.e. ADD, SUB, AND,
            // OR, XOR, SLT, SLTU, SLL, SRL, and SRA)
            // As in OPIMM, make sure you check funct7 to see if instructions
            // are valid.
            // After you've implemented decoding and executing OP
            // instructions, your processor should pass microtest 3.
            case (funct3)
        fnAND, fnOR, fnXOR, fnADD, fnSLT, fnSLTU, fnSLL, fnSR: begin

            case (funct7)
                7'b0000000: begin
                    case (funct3)
                        fnAND : dInst.aluFunc = And;
                        fnOR  : dInst.aluFunc = Or;
                        fnXOR : dInst.aluFunc = Xor;
                        fnADD : dInst.aluFunc = Add;
                        fnSLT : dInst.aluFunc = Slt;
                        fnSLTU: dInst.aluFunc = Sltu;
                        fnSLL : dInst.aluFunc = Sll;
                        fnSR  : dInst.aluFunc = Srl;
                    endcase
                end
                7'b0100000: begin

                    case (funct3)
                        fnADD : dInst.aluFunc = Sub;
                        fnSR  : dInst.aluFunc = Sra;
                        default: dInst.iType = Unsupported;
                    endcase
                end
                default: dInst.iType = Unsupported; 
            endcase
        end
        default: dInst.iType = Unsupported; 
    endcase
end
        opBranch: begin
            // TODO: Decode instructions of type BRANCH here (i.e. BEQ, BNE,
            // BLT, BGE, BLTU, and BGEU)

            // After you've implemented decoding and executing branch
            // instructions, your processor should pass microtest 4.
            dInst.iType = BRANCH;
            dInst.src1 = src1;
            dInst.src2 = src2;
            dInst.imm = immB32;
            case (funct3)
                fnBEQ: dInst.brFunc = Eq;
                fnBNE: dInst.brFunc = Neq;
                fnBLT: dInst.brFunc = Lt;
                fnBGE: dInst.brFunc = Ge;
                fnBLTU: dInst.brFunc = Ltu;
                fnBGEU: dInst.brFunc = Geu;
                default: dInst.iType = Unsupported;
            endcase
        end
                
            
        opJal: begin
            // TODO: Decode instructions of type JAL here
            // After you've implemented decoding and executing JAL
            // instructions, your processor should pass microtest 5.
            
        dInst = DecodedInst {iType: JAL, dst: validDst, src1: dSrc, src2: dSrc, imm: immJ32, brFunc: ?, aluFunc: ?, memFunc : ?};
        end
        opLoad: begin
            // TODO: Decode instructions of type LOAD here (i.e. LB, LH, LW, LBU, LHU)

            // After you've implemented decoding and executing Load
            // instructions, your processor should pass microtest 7.
            dInst.iType = LOAD;
            dInst.src1 = src1;
            dInst.dst = validDst;
            dInst.imm = immI32;
        
            case (funct3)
                fnLB: dInst.memFunc = Lb;
                fnLH: dInst.memFunc = Lh;
                fnLW: dInst.memFunc = Lw;
                fnLBU: dInst.memFunc = Lbu;
                fnLHU: dInst.memFunc = Lhu;
                default: dInst.iType = Unsupported;
            endcase
        
            dInst.brFunc = ?;
            dInst.aluFunc = Add; 
        end
        opStore: begin
            // TODO: Decode instructions of type STORE here (i.e. SB, SH, SW)
            // After you've implemented decoding and executing Store
            // instructions, your processor should pass microtest 8.
            dInst.iType = STORE;
            dInst.src1 = src1;
            dInst.src2 = src2;
            dInst.imm = immS32;

            case (funct3)
                fnSB: dInst.memFunc = Sb;
                fnSH: dInst.memFunc = Sh;
                fnSW: dInst.memFunc = Sw;
                default: dInst.iType = Unsupported;
            endcase

            dInst.dst = Invalid;
            dInst.brFunc = ?;
            dInst.aluFunc = Add; 
        end
        //dInst = DecodedInst {iType: STORE, dst: validDst, src1: dSrc, src2: dSrc, imm: immS32, brFunc: ?, aluFunc: ?, memFunc : ?};
        //end
        opJalr: begin
            // TODO: Decode instructions of type JALR here

            // After you've implemented decoding and executing JALR
            // instructions, your processor should pass microtest 9.
            case (funct3)
            fnJALR: begin
                dInst.iType = JALR;
                dInst.src1 = src1;
                dInst.src2 = dSrc;
                dInst.dst = validDst;
                dInst.imm = immI32;
                dInst.brFunc = ?;
                dInst.aluFunc = Add; 
                dInst.memFunc = ?;
            end
        endcase
end
        
        //end
    endcase
    return dInst;
endfunction