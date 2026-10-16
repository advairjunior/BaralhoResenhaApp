namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>O que alguém ainda tem que fazer antes de a carta passar sozinha.</summary>
public enum MotivoPendente
{
    /// <summary>Encheu o cofrinho ou levou dose: bebe e confirma.</summary>
    Beber,

    /// <summary>Eu Nunca: só ela fez, conta a história.</summary>
    Historia,

    /// <summary>Escolhido(a) no elogio: distribui os goles.</summary>
    Elogio,

    /// <summary>Correio: quem está na foto lê os bilhetes (e escolhe o favorito).</summary>
    Correio
}

public sealed record Pendente(Guid JogadorId, MotivoPendente Motivo);

/// <summary>
/// Passar a carta sozinho: quando todo mundo responde e quem tem alguma coisa
/// pendente (beber, contar a história…) confirma, a carta passa em 3 segundos.
/// Quem criou a sala não fica sobrecarregado. Cartas sem resposta no celular
/// (regra, elogios, aponta no 3) pedem "Pronto" de todo mundo. Qualquer um
/// pode segurar; aí só quem criou a sala passa.
/// </summary>
public sealed partial class Sala
{
    internal static readonly TimeSpan TempoParaPassar = TimeSpan.FromSeconds(3);

    /// <summary>Votação e Tribunal têm o suspense da foto: a contagem espera ele acabar.</summary>
    internal static readonly TimeSpan TempoDoSuspense = TimeSpan.FromSeconds(6);

    /// <summary>Celulares chegam alguns milissegundos antes da hora: tolera um pouco.</summary>
    private static readonly TimeSpan Folga = TimeSpan.FromMilliseconds(300);

    /// <summary>
    /// Confirma a pendência (bebi, contei…), responde "não me pegou" no Beba se
    /// ou marca "Pronto" nas cartas sem resposta.
    /// </summary>
    public void MarcarPronto(string token, int numeroDaRodada)
    {
        lock (_trinco)
        {
            var jogador = Reconhecer(token);
            if (!RodadaEmAndamento(numeroDaRodada) || Fase is FaseDaSala.Lobby or FaseDaSala.Fim) return;
            var rodada = Rodada!;
            if (Pendentes(rodada).Any(p => p.JogadorId == jogador.Id)) rodada.Confirmaram.Add(jogador.Id);
            else if (PodeFicarPronto(rodada)) rodada.Prontos.Add(jogador.Id);
            else throw new AcaoNaoPermitidaException(
                Fase == FaseDaSala.Revelada ? "Nada pendente para você nesta carta." : "Responda a carta primeiro.");
            Tocar();
        }
    }

    /// <summary>"Segura aí": para a contagem; a carta só passa pela mão de quem criou a sala.</summary>
    public void Segurar(string token, int numeroDaRodada)
    {
        lock (_trinco)
        {
            var jogador = Reconhecer(token);
            if (!RodadaEmAndamento(numeroDaRodada)) return;
            Rodada!.SeguradaPor = jogador.Nome;
            Rodada.PassaEm = null;
            Tocar();
        }
    }

    /// <summary>
    /// Quando a contagem acaba, cada celular pede para passar; o primeiro passa e
    /// os outros chegam numa rodada que já mudou, sem efeito.
    /// </summary>
    public void PassarSozinho(string token, int numeroDaRodada)
    {
        lock (_trinco)
        {
            Reconhecer(token);
            if (!RodadaEmAndamento(numeroDaRodada) || Fase is FaseDaSala.Lobby or FaseDaSala.Fim) return;
            if (Rodada!.PassaEm is not { } quando || _relogio.GetUtcNow() < quando - Folga) return;
            AvancarCarta();
            Tocar();
        }
    }

    /// <summary>Milissegundos até passar sozinho; nulo sem contagem.</summary>
    internal int? RestanteParaPassar(Rodada rodada) =>
        rodada.PassaEm is { } quando
            ? (int)Math.Max(0, Math.Round((quando - _relogio.GetUtcNow()).TotalMilliseconds))
            : null;

    /// <summary>Quem ainda tem o que fazer nesta carta (e ainda não confirmou).</summary>
    internal IReadOnlyList<Pendente> Pendentes(Rodada rodada)
    {
        var revelada = Fase == FaseDaSala.Revelada;
        if (!revelada && rodada.Carta.Modo != ModoDeJogo.BebaSe) return [];
        var pendentes = new List<Pendente>();
        void Adicionar(Guid? id, MotivoPendente motivo)
        {
            if (id is { } jogadorId && !rodada.Confirmaram.Contains(jogadorId) &&
                _jogadores.Any(j => j.Id == jogadorId) && pendentes.All(p => p.JogadorId != jogadorId))
                pendentes.Add(new Pendente(jogadorId, motivo));
        }
        if (revelada && rodada.Revelacao is { } revelacao)
        {
            Adicionar(revelacao.ContaAHistoria, MotivoPendente.Historia);
            if (revelacao.Elogio) foreach (var id in revelacao.Escolhidos) Adicionar(id, MotivoPendente.Elogio);
            if (rodada.Carta.Modo == ModoDeJogo.Correio) Adicionar(rodada.Alvo, MotivoPendente.Correio);
        }
        foreach (var id in rodada.BebemAgora) Adicionar(id, MotivoPendente.Beber);
        return pendentes;
    }

    /// <summary>
    /// "Pronto" de todo mundo só nas cartas sem resposta no celular; no Beba se,
    /// vale como "não me pegou".
    /// </summary>
    private bool PodeFicarPronto(Rodada rodada) => Fase != FaseDaSala.Revelada && rodada.Carta.Modo switch
    {
        ModoDeJogo.BebaSe or ModoDeJogo.RegraRelampago or ModoDeJogo.Elogios => true,
        // Aponta no 3: não tem resposta no celular.
        ModoDeJogo.MaisProvavel => !rodada.Votacao,
        _ => false
    };

    private bool ProntaParaPassar(Rodada rodada)
    {
        var todosProntos = _jogadores.Count > 0 && _jogadores.All(j => rodada.Prontos.Contains(j.Id));
        if (Fase == FaseDaSala.Revelada)
            return (rodada.Carta.Modo != ModoDeJogo.CasaisEmJogo || rodada.Acertou is not null) &&
                Pendentes(rodada).Count == 0;
        return rodada.Carta.Modo switch
        {
            ModoDeJogo.BebaSe => todosProntos && Pendentes(rodada).Count == 0,
            ModoDeJogo.RegraRelampago or ModoDeJogo.Elogios => todosProntos,
            ModoDeJogo.MaisProvavel when !rodada.Votacao => todosProntos,
            _ => false
        };
    }

    /// <summary>
    /// Depois de qualquer ação: liga a contagem quando a carta fica pronta e
    /// desliga se apareceu pendência nova (alguém jogou uma carta na manga).
    /// </summary>
    private void ConferirProntos()
    {
        if (Rodada is not { } rodada || !Configuracao.PassarSozinho || rodada.SeguradaPor is not null) return;
        if (Fase is not (FaseDaSala.Carta or FaseDaSala.Revelada)) return;
        if (!ProntaParaPassar(rodada))
        {
            rodada.PassaEm = null;
            return;
        }
        if (rodada.PassaEm is not null) return;
        var suspense = Fase == FaseDaSala.Revelada &&
            (rodada.Carta.Modo == ModoDeJogo.Tribunal || rodada.Carta.Modo == ModoDeJogo.MaisProvavel && rodada.Votacao);
        rodada.PassaEm = _relogio.GetUtcNow() + TempoParaPassar + (suspense ? TempoDoSuspense : TimeSpan.Zero);
    }

    private void AvancarCarta()
    {
        GastarUmaCartaDaRegra();
        Distribuir();
    }
}
