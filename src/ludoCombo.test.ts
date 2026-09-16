import { describe, expect, it } from 'vitest';
import { ludoOptions } from './engine';
import { bankSix, canBankSix, chooseComboDie, comboMove, comboRoll, newComboLudo } from './ludoCombo';
import type { ComboLudoState } from './ludoCombo';

function active(): ComboLudoState {
  return { ...newComboLudo(2), tokens: [[2,8,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1]] };
}
describe('Ludo: regra opcional de dados combinados', () => {
  it('só deixa guardar 6 quando há pelo menos duas peças em jogo', () => {
    const start=comboRoll(newComboLudo(2),6);
    expect(canBankSix(start)).toBe(false);
    expect(bankSix(start)).toBe(start);
    const one=comboRoll({...active(), tokens:[[2,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1],[-1,-1,-1,-1]]},6);
    expect(canBankSix(one)).toBe(false);
    expect(canBankSix(comboRoll(active(),6))).toBe(true);
  });
  it('6 + 4: permite escolher 4 primeiro para uma peça e 6 para outra sem novo bônus', () => {
    const saved=bankSix(comboRoll(active(),6));
    expect(saved.phase).toBe('roll');expect(saved.banked).toEqual([6]);
    const pair=comboRoll(saved,4);
    expect(pair.die).toBe(6);expect(pair.banked).toEqual([4]);expect(pair.phase).toBe('move');
    const chosen=chooseComboDie(pair);
    expect(chosen.die).toBe(4);expect(chosen.banked).toEqual([6]);
    const first=comboMove(chosen,0);
    expect(first.tokens[0][0]).toBe(6);expect(first.die).toBe(6);expect(first.current).toBe(0);
    const second=comboMove(first,1);
    expect(second.tokens[0][1]).toBe(14);expect(second.current).toBe(2);
    expect(second.phase).toBe('roll');expect(second.banked).toEqual([]);expect(second.combined).toBe(false);
  });
  it('6 + 4: permite mover primeiro com o 6 e depois com o 4', () => {
    const pair=comboRoll(bankSix(comboRoll(active(),6)),4);
    const first=comboMove(pair,1);
    expect(first.tokens[0][1]).toBe(14);expect(first.die).toBe(4);
    const second=comboMove(first,0);
    expect(second.tokens[0][0]).toBe(6);expect(second.current).toBe(2);
  });
  it('dois seis dão próxima jogada após gastar ambos, mas o terceiro seis perde a vez', () => {
    const pair=comboRoll(bankSix(comboRoll(active(),6)),6);
    expect(pair.extraAfterCombo).toBe(true);
    const after=comboMove(comboMove(pair,0),1);
    expect(after.current).toBe(0);expect(after.phase).toBe('roll');expect(after.sixes).toBe(2);
    const penalty=comboRoll(after,6);
    expect(penalty.current).toBe(2);expect(penalty.sixes).toBe(0);
  });
  it('um seis depois de dois seis anteriores descarta os dados guardados', () => {
    const ready={...active(),sixes:1};
    const saved=bankSix(comboRoll(ready,6));
    const penalty=comboRoll(saved,6);
    expect(penalty.current).toBe(2);expect(penalty.banked).toEqual([]);expect(penalty.combined).toBe(false);
  });
  it('regra tradicional continua funcionando quando não se guarda o seis', () => {
    const six=comboRoll(newComboLudo(2),6);
    expect(ludoOptions(six)).toEqual([0,1,2,3]);
    const moved=comboMove(six,0);
    expect(moved.tokens[0][0]).toBe(0);expect(moved.current).toBe(0);expect(moved.phase).toBe('roll');
  });
});
