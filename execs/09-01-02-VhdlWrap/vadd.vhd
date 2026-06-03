-- 已有的 VHDL IP：带使能的寄存器加法器  q <= a + b
library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;
entity vadd is
  port ( clk, rst_n, en : in  std_logic;
         a, b           : in  std_logic_vector(7 downto 0);
         q              : out std_logic_vector(7 downto 0) );
end entity;
architecture rtl of vadd is
  signal r : unsigned(7 downto 0);
begin
  process(clk, rst_n) begin
    if rst_n = '0' then r <= (others => '0');
    elsif rising_edge(clk) then if en = '1' then r <= unsigned(a) + unsigned(b); end if; end if;
  end process;
  q <= std_logic_vector(r);
end architecture;
