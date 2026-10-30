namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// 🙈 Quem sou eu?: a carta é um segredo que todo mundo vê, menos a pessoa da
/// vez (o alvo, em rodízio). Ela sabe só a categoria e pergunta "sim ou não" em
/// voz alta contra o cronômetro. Quem criou a sala marca o resultado: acertou,
/// ganha carta na manga; o tempo acabou, leva ponto.
/// </summary>
public sealed partial class Sala
{
    public void ResultadoDoQuemSouEu(string token, int numeroDaRodada, bool acertou)
    {
        lock (_trinco)
        {
            ExigirAnfitriao(token, "Quem marca o resultado é quem criou a sala.");
            if (!RodadaEmAndamento(numeroDaRodada) || Fase != FaseDaSala.Carta) return;
            var rodada = Rodada!;
            if (rodada.Carta.Modo != ModoDeJogo.QuemSouEu)
                throw new AcaoNaoPermitidaException("Só vale no Quem sou eu.");
            var daVez = _jogadores.FirstOrDefault(j => j.Id == rodada.Alvo);
            IReadOnlyList<Guid> ele = daVez is null ? [] : [daVez.Id];
            // Revelação antes dos pontos: as cartas na manga olham a conta desta carta.
            rodada.Revelacao = new Revelacao([], [], [], acertou ? [] : ele, null) { Escolhidos = acertou ? ele : [] };
            if (daVez is not null)
            {
                if (acertou) DarCarta(daVez);
                else Pegar(daVez);
            }
            Fase = FaseDaSala.Revelada;
            Tocar();
        }
    }
}
