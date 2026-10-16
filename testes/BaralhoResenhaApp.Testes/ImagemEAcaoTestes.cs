using BaralhoResenhaApp.Api.Dominio;
using BaralhoResenhaApp.Api.Infraestrutura;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// Imagem e Ação: só quem faz a mímica vê a palavra; a turma vê a dica.
/// Até 5 pessoas, uma faz para todos; de 6 a 8, dois times; 9 ou mais, três.
/// </summary>
public sealed class ImagemEAcaoTestes
{
    private static readonly Carta Mimica = new("ia-1", ModoDeJogo.ImagemEAcao, NivelDaCarta.Leve,
        "Escovar os dentes", Categoria: "Ação");

    private static readonly string[] Nomes = ["Ana", "Beto", "Caio", "Duda", "Edu", "Fabi", "Gil", "Hugo", "Iara"];

    private sealed record Mesa(Sala Sala, Jogador[] Todos)
    {
        public Jogador Ana => Todos[0];
        public Rodada Rodada => Sala.Rodada!;
        public Jogador Quem(Guid id) => Todos.Single(j => j.Id == id);
    }

    private static Mesa Montar(int pessoas, int seed = 5)
    {
        var sala = new Sala("ABCD", new Baralho([Mimica]), new Random(seed));
        var todos = Nomes.Take(pessoas).Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.ImagemEAcao], true,
            Ritmo: RitmoDaBebida.Raiz));
        sala.Comecar(todos[0].Token);
        return new Mesa(sala, todos);
    }

    [Theory]
    [InlineData(3, 1)]
    [InlineData(5, 1)]
    [InlineData(6, 2)]
    [InlineData(8, 2)]
    [InlineData(9, 3)]
    public void QuantidadeDeTimesDependeDaMesa(int pessoas, int times)
    {
        var mesa = Montar(pessoas);

        Assert.Equal(times, mesa.Rodada.Times.Count);
        Assert.Equal(pessoas, mesa.Rodada.Times.Sum(t => t.Jogadores.Count));
        Assert.All(mesa.Rodada.Times, t => Assert.Contains(t.Mimico, t.Jogadores));
        // Times equilibrados: no máximo um de diferença.
        var tamanhos = mesa.Rodada.Times.Select(t => t.Jogadores.Count).ToList();
        Assert.True(tamanhos.Max() - tamanhos.Min() <= 1);
    }

    [Fact]
    public void SoQuemFazAMimicaVeAPalavraOsOutrosVeemADica()
    {
        var mesa = Montar(6);
        var mimicos = mesa.Rodada.Times.Select(t => t.Mimico).ToHashSet();
        var mimico = mesa.Quem(mesa.Rodada.Times[0].Mimico);
        var palpiteiro = mesa.Todos.First(j => !mimicos.Contains(j.Id));

        Assert.Equal("Escovar os dentes", mesa.Sala.Visao(mimico.Token).Rodada!.Texto);
        var visaoDoPalpiteiro = mesa.Sala.Visao(palpiteiro.Token).Rodada!;
        Assert.DoesNotContain("Escovar", visaoDoPalpiteiro.Texto);
        Assert.Equal("Ação · 3 palavras", visaoDoPalpiteiro.Dica);
    }

    [Fact]
    public void NosTimesQuemPerdeLevaPontoEAPalavraApareceParaTodos()
    {
        var mesa = Montar(6);
        var vencedor = mesa.Rodada.Times[1];
        var perdedor = mesa.Rodada.Times[0];

        Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.ResultadoDaMimica(mesa.Quem(vencedor.Mimico).Token, mesa.Rodada.Numero, 1));
        mesa.Sala.ResultadoDaMimica(mesa.Ana.Token, mesa.Rodada.Numero, 1);

        Assert.Equal(FaseDaSala.Revelada, mesa.Sala.Fase);
        Assert.Equal(1, mesa.Rodada.Revelacao!.TimeVencedor);
        Assert.Equal(perdedor.Jogadores.Order(), mesa.Rodada.Revelacao.Perderam.Order());
        Assert.All(perdedor.Jogadores, id => Assert.Equal(1, mesa.Quem(id).Pontos));
        Assert.All(vencedor.Jogadores, id => Assert.Equal(0, mesa.Quem(id).Pontos));
        Assert.Equal(1, mesa.Quem(vencedor.Mimico).Estatisticas.MimicasAcertadas);
        var qualquerUm = mesa.Quem(perdedor.Jogadores.First(id => id != perdedor.Mimico));
        Assert.Equal("Escovar os dentes", mesa.Sala.Visao(qualquerUm.Token).Rodada!.Texto);
    }

    [Fact]
    public void NinguemAcertouOsMimicosLevamOPonto()
    {
        var mesa = Montar(6);

        mesa.Sala.ResultadoDaMimica(mesa.Ana.Token, mesa.Rodada.Numero, null);

        var mimicos = mesa.Rodada.Times.Select(t => t.Mimico).Order();
        Assert.Equal(mimicos, mesa.Rodada.Revelacao!.Perderam.Order());
        Assert.Null(mesa.Rodada.Revelacao.TimeVencedor);
    }

    [Fact]
    public void ComUmaPessoaSoAcertarLivraTodoMundoENaoAcertarPegaOMimico()
    {
        var acertou = Montar(4);
        acertou.Sala.ResultadoDaMimica(acertou.Ana.Token, acertou.Rodada.Numero, 0);
        Assert.Empty(acertou.Rodada.Revelacao!.Perderam);

        var errou = Montar(4);
        errou.Sala.ResultadoDaMimica(errou.Ana.Token, errou.Rodada.Numero, null);
        Assert.Equal([errou.Rodada.Times[0].Mimico], errou.Rodada.Revelacao!.Perderam);
    }

    [Fact]
    public void QuemAindaNaoFezMimicaTemAVez()
    {
        var mesa = Montar(3);
        var mimicos = new HashSet<Guid>();
        for (var i = 0; i < 3; i++)
        {
            mimicos.Add(mesa.Rodada.Times[0].Mimico);
            mesa.Sala.Proxima(mesa.Ana.Token, mesa.Rodada.Numero);
        }

        Assert.Equal(3, mimicos.Count);
    }

    [Fact]
    public void BaralhoOficialTemMimicasComCategoria()
    {
        var baralho = CatalogoDeCartas.Carregar();
        var mimicas = baralho.Cartas.Where(c => c.Modo == ModoDeJogo.ImagemEAcao).ToList();

        Assert.True(mimicas.Count >= 50);
        Assert.All(mimicas, c => Assert.False(string.IsNullOrWhiteSpace(c.Categoria)));
        Assert.True(mimicas.Select(c => c.Categoria).Distinct().Count() >= 5);
    }
}
