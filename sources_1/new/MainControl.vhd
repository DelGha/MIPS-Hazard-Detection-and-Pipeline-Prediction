library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MainControl is
    Port ( Instr : in STD_LOGIC_VECTOR(15 downto 0);
           RegDst : out STD_LOGIC;
           ExtOp : out STD_LOGIC;
           ALUSrc : out STD_LOGIC;
           Branch : out STD_LOGIC;
           Jump : out STD_LOGIC;
           ALUOp : out STD_LOGIC_VECTOR(2 downto 0);
           MemRead : out STD_LOGIC;
           MemWrite : out STD_LOGIC;
           MemtoReg : out STD_LOGIC;
           RegWrite : out STD_LOGIC);
end MainControl;

architecture Behavioral of MainControl is
begin

    process(Instr)
    begin
        RegDst <= '0'; ExtOp <= '0'; ALUSrc <= '0'; 
        Branch <= '0'; Jump <= '0'; MemRead <= '0';
        MemWrite <= '0'; MemtoReg <= '0'; RegWrite <= '0';
        ALUOp <= "000";
        case (Instr(15 downto 13)) is 
            when "000" => -- R type
                RegDst <= '1';
                RegWrite <= '1';
                ALUOp <= "000";
            when "001" => -- ADDI
                ExtOp <= '1';
                ALUSrc <= '1';
                RegWrite <= '1';
                ALUOp <= "001";
            when "010" => -- LW
                ExtOp <= '1';
                ALUSrc <= '1';
                MemtoReg <= '1';
                RegWrite <= '1';
                MemRead <= '1';
                ALUOp <= "001";
            when "011" => -- SW
                ExtOp <= '1';
                ALUSrc <= '1';
                MemWrite <= '1';
                ALUOp <= "001";
            when "100" => -- BEQ - incercam BNEQ
                RegDst <= '1';
                ExtOp <= '1';
                Branch <= '1';
                ALUOp <= "100";
            when "101" => -- ANDI
                ALUSrc <= '1';
                RegWrite <= '1';
                ALUOp <= "101";
            when "110" => -- ORI
                ALUSrc <= '1';
                RegWrite <= '1';
                ALUOp <= "110";
            when "111" => -- J
                Jump <= '1';
            when others => 
                RegDst <= '0'; ExtOp <= '0'; ALUSrc <= '0'; 
                Branch <= '0'; Jump <= '0'; MemRead <= '0';
                MemWrite <= '0'; MemtoReg <= '0'; RegWrite <= '0';
                ALUOp <= "XXX";
        end case;
    end process;		

end Behavioral;