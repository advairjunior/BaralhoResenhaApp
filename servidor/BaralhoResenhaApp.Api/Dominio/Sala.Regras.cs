namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// Regra-relâmpago que acontece de verdade: a cada carta sai uma isca
/// (entrevista, pergunta, missão ou piada) e quem criou a sala marca quem
/// vacilou. Sem isso, "só pode falar cantando" vira só silêncio.
/// </summary>
public sealed partial class Sala
{
    internal const int PerguntasDaEntrevista = 3;

    private readonly HashSet<string> _iscasUsadas = [];
    private IReadOnlyList<string> _iscasDaRegra = [];

    /// <summary>Quem criou a sala toca em quem quebrou a regra; tocar de novo desfaz.</summary>
    public void MarcarVacilo(string token, int numeroDaRodada, Guid jogadorId)
    {
        lock (_trinco)
        {
            ExigirAnfitriao(token, "Quem marca o vacilo é quem criou a sala.");
            if (!RodadaEmAndamento(numeroDaRodada)) return;
            if (Regra is null) throw new AcaoNaoPermitidaException("Não tem regra valendo agora.");
            var vacilao = _jogadores.FirstOrDefault(j => j.Id == jogadorId)
                ?? throw new AcaoNaoPermitidaException("Essa pessoa não está na sala.");
            if (Rodada!.Vacilaram.Remove(vacilao.Id))
            {
                Despegar(vacilao);
                vacilao.Estatisticas.Vacilos--;
            }
            else
            {
                Rodada.Vacilaram.Add(vacilao.Id);
                Pegar(vacilao);
                vacilao.Estatisticas.Vacilos++;
            }
            Tocar();
        }
    }

    private void ComecarRegra(Carta carta, string texto, Jogador? alvo)
    {
        _iscasDaRegra = carta.Iscas ?? [];
        var regra = new RegraAtiva(texto, RodadasDaRegra) { Alvo = alvo?.Id, Isca = carta.Isca };
        Regra = regra with { Desafio = NovoDesafio(regra, primeiraCarta: true) };
    }

    private DesafioDaRegra? NovoDesafio(RegraAtiva regra, bool primeiraCarta)
    {
        var alvo = _jogadores.FirstOrDefault(j => j.Id == regra.Alvo);
        var iscas = _baralho.Iscas;
        Guid? OutroQue(Jogador? quem) =>
            _jogadores.Where(j => j.Id != quem?.Id).OrderBy(_ => _sorteio.Next()).FirstOrDefault()?.Id;

        // Regra sobre alguém que saiu da sala fica sem isca.
        if (regra.Isca is not (IscaDaRegra.Nenhuma or IscaDaRegra.Conversa) && alvo is null) return null;
        return regra.Isca switch
        {
            // Na carta da regra, entrevista completa; depois, uma pergunta por carta.
            IscaDaRegra.Entrevista => new(regra.Isca, OutroQue(alvo), alvo!.Id,
                Sortear(iscas.Perguntas, primeiraCarta ? PerguntasDaEntrevista : 1)),
            IscaDaRegra.Conversa => new(regra.Isca, null, OutroQue(null),
                Sortear(_iscasDaRegra.Count > 0 ? _iscasDaRegra : iscas.Perguntas, 1)),
            IscaDaRegra.Risada => new(regra.Isca, OutroQue(alvo), alvo!.Id, Sortear(iscas.Risadas, 1)),
            IscaDaRegra.Mestre => new(regra.Isca, alvo!.Id, OutroQue(alvo), Sortear(iscas.Perguntas, 1)),
            IscaDaRegra.Piada => new(regra.Isca, alvo!.Id, null, Sortear(iscas.Piadas, 1)),
            _ => null
        };
    }

    /// <summary>Sorteia sem repetir na noite; quando um monte acaba, embaralha de novo.</summary>
    private List<string> Sortear(IReadOnlyList<string> monte, int quantidade)
    {
        var livres = monte.Where(t => !_iscasUsadas.Contains(t)).ToList();
        if (livres.Count < quantidade)
        {
            foreach (var texto in monte) _iscasUsadas.Remove(texto);
            livres = monte.ToList();
        }
        var escolhidas = livres.OrderBy(_ => _sorteio.Next()).Take(quantidade).ToList();
        _iscasUsadas.UnionWith(escolhidas);
        return escolhidas;
    }
}
