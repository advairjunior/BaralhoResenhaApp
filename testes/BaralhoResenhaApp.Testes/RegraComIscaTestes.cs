using BaralhoResenhaApp.Api.Dominio;
using BaralhoResenhaApp.Api.Infraestrutura;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// Regra boa sem ninguém falando é regra desperdiçada: a cada carta o jogo
/// dá uma isca (entrevista, pergunta, missão, piada) e quem criou a sala
/// marca quem vacilou.
/// </summary>
public sealed class RegraComIscaTestes
{
    private static readonly Iscas Banco = new(
        Perguntas: ["P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8"],
        Risadas: ["R1", "R2"],
        Piadas: ["Piada 1", "Piada 2"]);

    private static readonly Carta Comum = new("bs-1", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "Beba se usa óculos.");

    private sealed record Mesa(Sala Sala, Jogador[] Todos)
    {
        public Jogador Ana => Todos[0];
        public Jogador Quem(Guid? id) => Todos.Single(j => j.Id == id);
        public void Proxima() => Sala.Proxima(Ana.Token, Sala.Rodada!.Numero);
    }

    /// <summary>A primeira carta é a regra; as seguintes, Beba se.</summary>
    private static Mesa Montar(Carta regra, int seed = 3)
    {
        var sala = new Sala("ABCD", new Baralho([regra, Comum], Banco), new Random(seed));
        var todos = new[] { "Ana", "Beto", "Caio", "Duda" }.Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token,
            new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.RegraRelampago], true, Ritmo: RitmoDaBebida.Raiz));
        sala.Comecar(todos[0].Token);
        sala.Configurar(todos[0].Token,
            new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.BebaSe, ModoDeJogo.RegraRelampago], true,
                Ritmo: RitmoDaBebida.Raiz));
        return new Mesa(sala, todos);
    }

    [Fact]
    public void QuemSoPodeFalarCantandoGanhaUmaEntrevistaEUmaPerguntaPorCarta()
    {
        var mesa = Montar(new("rr-1", ModoDeJogo.RegraRelampago, NivelDaCarta.Leve,
            "{jogador} só pode falar cantando.", Isca: IscaDaRegra.Entrevista));
        var regra = mesa.Sala.Regra!;
        var cantor = mesa.Quem(regra.Alvo);

        Assert.Equal($"{cantor.Nome} só pode falar cantando.", regra.Texto);
        var entrevista = regra.Desafio!;
        Assert.Equal(IscaDaRegra.Entrevista, entrevista.Tipo);
        Assert.Equal(cantor.Id, entrevista.Para);
        Assert.NotEqual(cantor.Id, entrevista.Quem);
        Assert.Equal(3, entrevista.Textos.Count);

        mesa.Proxima();
        var pergunta = mesa.Sala.Visao(mesa.Ana.Token).Regra!.Desafio!;
        Assert.Equal(cantor.Id, pergunta.Para);
        Assert.Single(pergunta.Textos);
        Assert.DoesNotContain(pergunta.Textos[0], entrevista.Textos);
    }

    [Fact]
    public void RegraDaMesaUsaAsIscasDaPropriaCartaPrimeiro()
    {
        var mesa = Montar(new("rr-2", ModoDeJogo.RegraRelampago, NivelDaCarta.Leve,
            "Proibido falar de trabalho.", Isca: IscaDaRegra.Conversa,
            Iscas: ["Como anda o trabalho?", "Seu chefe é gente boa?"]));

        var desafio = mesa.Sala.Regra!.Desafio!;
        Assert.Null(desafio.Quem);
        Assert.NotNull(desafio.Para);
        Assert.Contains(desafio.Textos.Single(), new[] { "Como anda o trabalho?", "Seu chefe é gente boa?" });
    }

    [Fact]
    public void MestreDasPerguntasRecebePerguntasParaFazerEPiadistaRecebePiada()
    {
        var mestre = Montar(new("rr-3", ModoDeJogo.RegraRelampago, NivelDaCarta.Leve,
            "{jogador} é Mestre das Perguntas.", Isca: IscaDaRegra.Mestre));
        var desafio = mestre.Sala.Regra!.Desafio!;
        Assert.Equal(mestre.Sala.Regra.Alvo, desafio.Quem);
        Assert.NotEqual(desafio.Quem, desafio.Para);

        var piadista = Montar(new("rr-4", ModoDeJogo.RegraRelampago, NivelDaCarta.Leve,
            "Quem rir de piada ruim do {jogador} bebe.", Isca: IscaDaRegra.Piada));
        var piada = piadista.Sala.Regra!.Desafio!;
        Assert.Equal(piadista.Sala.Regra.Alvo, piada.Quem);
        Assert.StartsWith("Piada", piada.Textos.Single());

        var risada = Montar(new("rr-5", ModoDeJogo.RegraRelampago, NivelDaCarta.Leve,
            "Toda vez que {jogador} rir, todo mundo bebe.", Isca: IscaDaRegra.Risada));
        var missao = risada.Sala.Regra!.Desafio!;
        Assert.Equal(risada.Sala.Regra.Alvo, missao.Para);
        Assert.NotEqual(missao.Para, missao.Quem);
        Assert.StartsWith("R", missao.Textos.Single());
    }

    [Fact]
    public void QuandoARegraAcabaAIscaVaiJunto()
    {
        var mesa = Montar(new("rr-1", ModoDeJogo.RegraRelampago, NivelDaCarta.Leve,
            "{jogador} só pode falar cantando.", Isca: IscaDaRegra.Entrevista));
        for (var i = 0; i < Sala.RodadasDaRegra; i++)
        {
            mesa.Proxima();
            Assert.NotNull(mesa.Sala.Regra?.Desafio);
        }

        mesa.Sala.Configurar(mesa.Ana.Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.BebaSe], true));
        mesa.Proxima();
        Assert.Null(mesa.Sala.Regra);
    }

    [Fact]
    public void QuemCriouASalaMarcaQuemVacilouNaRegra()
    {
        var mesa = Montar(new("rr-1", ModoDeJogo.RegraRelampago, NivelDaCarta.Leve,
            "{jogador} só pode falar cantando.", Isca: IscaDaRegra.Entrevista));
        var cantor = mesa.Quem(mesa.Sala.Regra!.Alvo);
        var rodada = mesa.Sala.Rodada!.Numero;

        Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.MarcarVacilo(mesa.Todos[1].Token, rodada, cantor.Id));
        mesa.Sala.MarcarVacilo(mesa.Ana.Token, rodada, cantor.Id);

        Assert.Equal([cantor.Id], mesa.Sala.Visao(mesa.Ana.Token).Rodada!.Vacilaram);
        Assert.Equal(1, cantor.Pontos);
        Assert.Equal(1, cantor.Estatisticas.Vacilos);

        // Tocou sem querer: tocar de novo desfaz.
        mesa.Sala.MarcarVacilo(mesa.Ana.Token, rodada, cantor.Id);
        Assert.Equal(0, cantor.Pontos);
        Assert.Empty(mesa.Sala.Rodada!.Vacilaram);
    }

    [Fact]
    public void SemRegraValendoNaoTemVacilo()
    {
        var sala = new Sala("ABCD", new Baralho([Comum], Banco), new Random(1));
        var ana = sala.Entrar("Ana", false);
        var beto = sala.Entrar("Beto", false);
        sala.Configurar(ana.Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.BebaSe], true));
        sala.Comecar(ana.Token);

        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => sala.MarcarVacilo(ana.Token, sala.Rodada!.Numero, beto.Id));
        Assert.Equal("Não tem regra valendo agora.", erro.Message);
    }

    [Fact]
    public void QuemMaisVacilaLevaPremio()
    {
        var beto = new Jogador { Id = Guid.NewGuid(), Token = "b", Nome = "Beto" };
        beto.Estatisticas.Vacilos = 2;

        var premio = PremiosDaNoite.Calcular([beto], []).Single();

        Assert.Equal("Vacilão(ona) da regra", premio.Titulo);
        Assert.Equal("Quebrou as regras 2 vezes", premio.Descricao);
    }

    [Fact]
    public void BancoOficialTemIscasECartasComAlvoTemJogador()
    {
        var baralho = CatalogoDeCartas.Carregar();

        Assert.True(baralho.Iscas.Perguntas.Count >= 30);
        Assert.True(baralho.Iscas.Risadas.Count >= 8);
        Assert.True(baralho.Iscas.Piadas.Count >= 10);
        var comAlvo = baralho.Cartas.Where(c => c.Isca is IscaDaRegra.Entrevista or IscaDaRegra.Mestre
            or IscaDaRegra.Risada or IscaDaRegra.Piada).ToList();
        Assert.NotEmpty(comAlvo);
        Assert.All(comAlvo, c => Assert.Contains("{jogador}", c.Texto));
        Assert.All(baralho.Cartas.Where(c => c.Isca != IscaDaRegra.Nenhuma),
            c => Assert.Equal(ModoDeJogo.RegraRelampago, c.Modo));
    }
}
