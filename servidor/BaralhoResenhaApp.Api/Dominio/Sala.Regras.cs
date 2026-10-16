namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>
/// Regra-relâmpago que acontece de verdade: a cada carta sai uma isca
/// (entrevista, pergunta, missão ou piada) e quem criou a sala marca quem
/// vacilou. Sem isso, "só pode falar cantando" vira só silêncio.
/// </summary>
public sealed partial class Sala
{
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
            if (!QuemPodeVacilar(Regra).Contains(vacilao.Id))
                throw new AcaoNaoPermitidaException(
                    $"Nessa regra, só {_jogadores.First(j => j.Id == Regra.Alvo).Nome} pode vacilar.");
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

    /// <summary>
    /// Regra sobre a fala ou a risada de uma pessoa ("só pode falar cantando",
    /// "proibido sorrir"): só ela vacila. Regra da mesa: qualquer um.
    /// </summary>
    internal IReadOnlyList<Guid> QuemPodeVacilar(RegraAtiva regra) =>
        regra.Isca is IscaDaRegra.Entrevista or IscaDaRegra.Risada && _jogadores.Any(j => j.Id == regra.Alvo)
            ? [regra.Alvo!.Value]
            : _jogadores.Select(j => j.Id).ToList();

    private void ComecarRegra(Carta carta, string texto, Jogador? alvo)
    {
        _iscasDaRegra = carta.Iscas ?? [];
        var regra = new RegraAtiva(texto, RodadasDaRegra)
        {
            Alvo = alvo?.Id,
            Isca = carta.Isca,
            Entrevistador = carta.Isca == IscaDaRegra.Entrevista ? OutroQue(alvo) : null,
        };
        // A carta da regra só apresenta ("Ana entrevista Beto"); as perguntas vêm
        // nas vezes da regra, uma carta sim, outra não.
        Regra = regra with { Desafio = NovoDesafio(regra) is { } desafio ? desafio with { Textos = [] } : null };
    }

    /// <summary>A regra tem isca para intercalar com as cartas comuns?</summary>
    internal bool TemVez(RegraAtiva regra) =>
        regra.Isca == IscaDaRegra.Conversa ||
        regra.Isca != IscaDaRegra.Nenhuma && _jogadores.Any(j => j.Id == regra.Alvo);

    /// <summary>
    /// Depois de uma carta comum, com regra de isca valendo, vem a vez da regra:
    /// uma carta só com a pergunta (ou missão, piada…), para ninguém esquecer.
    /// </summary>
    private bool DistribuirVezDaRegra()
    {
        if (Regra is not { } regra || !TemVez(regra) || Rodada is not { } anterior ||
            anterior.VezDaRegra || anterior.Carta.Modo == ModoDeJogo.RegraRelampago ||
            NovoDesafio(regra) is not { } desafio)
            return false;
        CartaTiradaPor = null;
        Rodada = new Rodada
        {
            Numero = anterior.Numero + 1,
            Carta = new Carta("vez-da-regra", ModoDeJogo.RegraRelampago, anterior.Carta.Nivel, regra.Texto),
            Texto = regra.Texto,
            VezDaRegra = true,
        };
        Regra = regra with { Desafio = desafio };
        Fase = FaseDaSala.Carta;
        return true;
    }

    private Guid? OutroQue(Jogador? quem) =>
        _jogadores.Where(j => j.Id != quem?.Id).OrderBy(_ => _sorteio.Next()).FirstOrDefault()?.Id;

    private DesafioDaRegra? NovoDesafio(RegraAtiva regra)
    {
        var alvo = _jogadores.FirstOrDefault(j => j.Id == regra.Alvo);
        var iscas = _baralho.Iscas;

        // Regra sobre alguém que saiu da sala fica sem isca.
        if (regra.Isca is not (IscaDaRegra.Nenhuma or IscaDaRegra.Conversa) && alvo is null) return null;
        return regra.Isca switch
        {
            // Quem entrevista é o mesmo a regra inteira; se saiu da sala, entra outro.
            IscaDaRegra.Entrevista => new(regra.Isca,
                _jogadores.Any(j => j.Id == regra.Entrevistador) ? regra.Entrevistador : OutroQue(alvo),
                alvo!.Id, Sortear(iscas.Perguntas, 1)),
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
